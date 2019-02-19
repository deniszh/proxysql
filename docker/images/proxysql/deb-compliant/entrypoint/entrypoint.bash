#!/bin/bash
# Delete package if exists
rm -f /opt/proxysql/binaries/proxysql_${CURVER}-${PKG_RELEASE}_amd64.deb || true && \
# Cleanup relic directories from a previously failed build
rm -f /opt/proxysql/proxysql.ctl || true && \
# Clean and build dependancies and source
cd /opt/proxysql && \
# Patch for Ubuntu 12
if [ "`grep Ubuntu /etc/issue | awk '{print $2}' | cut -d. -f1`" == "12" ]; then
    # restore c++11 compatibility just in case
    sed -i -e 's/c++0x/c++11/' lib/Makefile
    sed -i -e 's/c++0x/c++11/' src/Makefile
    # install new g++
    apt-get install -y python-software-properties
    add-apt-repository ppa:ubuntu-toolchain-r/test
    add-apt-repository ppa:roblib/ppa
    wget https://repo.percona.com/apt/percona-release_0.1-4.precise_all.deb
    dpkg -i percona-release_0.1-4.precise_all.deb
    apt-get update
    apt-get install -y cmake gcc-4.8 g++-4.8 libboost-all-dev libperconaserverclient20=5.7.18-16-1.precise libperconaserverclient20-dev=5.7.18-16-1.precise percona-server-source-5.7=5.7.18-16-1.precise
    apt-get -y autoremove && apt-get -y remove libmysqlclient-dev ibmysqlclient18 libmysqlclient18-dev libmysqlclient18.1 libmysqlclient18.1-de
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50
    cd /opt/proxysql/deps/re2/
    mv re2.tar.gz /tmp/
    wget -O re2.tar.gz https://github.com/sysown/proxysql/raw/v1.3.9/deps/re2/re2-20140304.tgz
    cd /opt/proxysql
fi
# cloning binlog server
cd /opt && git clone https://github.com/sysown/proxysql_mysqlbinlog.git && cd /opt/proxysql_mysqlbinlog && \
# building libslave
cd /usr/src/percona-server/ && tar -xpzf percona-server-5.7_5.7.18-16.orig.tar.gz && cp -fv /usr/src/percona-server/percona-server-5.7.18-16/include/hash.h /usr/include/mysql/ && \
cd /usr/lib/x86_64-linux-gnu/ && ln -s libperconaserverclient.a libmysqlclient.a && ln -s libperconaserverclient.so libmysqlclient.so && \
cd /opt/proxysql_mysqlbinlog/libslave/ && cmake . && make slave_a && \
# building binlog server
cd ../ && make && \
mkdir -p /opt/proxysql/bin && \
cp /opt/proxysql_mysqlbinlog/proxysql_binlog_reader /opt/proxysql/bin/proxysql_binlog_reader && \
# build proxysql
cd /opt/proxysql && \
${MAKE} cleanbuild && \
${MAKE} ${MAKEOPT} build_deps && \
${MAKE} ${MAKEOPT} && \
# Prepare package files and build package
cp /root/ctl/proxysql.ctl /opt/proxysql/proxysql.ctl && \
sed -i "s/PKG_VERSION_CURVER/${CURVER}/g" /opt/proxysql/proxysql.ctl && \
cp /opt/proxysql/src/proxysql /opt/proxysql/ && \
equivs-build proxysql.ctl && \
mv /opt/proxysql/proxysql_${CURVER}_amd64.deb ./binaries/proxysql_${CURVER}-${PKG_RELEASE}_amd64.deb && \
# Cleanup current build
# Unpatch Ubuntu 12
if [ "`grep Ubuntu /etc/issue | awk '{print $2}' | cut -d. -f1`" == "12" ]; then
        mv /tmp/re2.tar.gz /opt/proxysql/deps/re2/
fi
rm -f /opt/proxysql/proxysql.ctl /opt/proxysql/proxysql
