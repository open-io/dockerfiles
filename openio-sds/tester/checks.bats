#!/usr/bin/env bats

load "${BATS_HELPERS_DIR}/load.bash"

CURL_OPTS=("--insecure" "--fail" "--location" "--silent" "--verbose" "--show-error")


# Tests
@test 'Account - status' {
  run retry 60 2 curl "${CURL_OPTS[@]}" "${SUT_IP}:6009/status"
  assert_success
}

@test 'Conscience - up' {
  retry_contains_output 10 1 "PING OK" docker exec -t "${SUT_ID}" /usr/bin/oio-tool ping "${SUT_IP}:6000"
}

@test 'rawx - status' {
  retry_contains_output 10 1 "counter req.hits" curl "${CURL_OPTS[@]}" "${SUT_IP}:6200/stat"
  retry_contains_output 10 1 "counter req.hits.raw 0" curl "${CURL_OPTS[@]}" "${SUT_IP}:6200/stat"
}

@test 'rdir - up' {
  retry_contains_output 10 1 "succeeded" nc -zv "${SUT_IP}" 6300 \
    || retry_contains_output 10 1 "Connected to" nc -zv "${SUT_IP}" 6300
}

@test 'Redis - up' {
  retry_contains_output 10 1 "PONG" redis-cli -h "${SUT_IP}" -p 6011 ping
}

@test 'Gridinit - Status of services' {
  retry 10 1 docker exec -t "${SUT_ID}" /usr/bin/gridinit_cmd status
}

@test 'Cluster - Status ' {
  retry_contains_output 10 1 "Up" docker exec -t "${SUT_ID}" openio cluster list -c Up -f csv --oio-ns OPENIO
  retry_refute_output 30 5 "False" docker exec -t "${SUT_ID}" openio cluster list -c Up -f csv --oio-ns OPENIO
}

@test 'Cluster - Score unlock' {
  retry_refute_output 10 1 '^0$' bash -c 'openio cluster list -c Score -f csv --oio-ns OPENIO |sed -e "s@^@^@" |cat -evt'
}

@test 'OIO - push object' {
  retry 12 5 docker exec -t "${SUT_ID}" openio object create MY_CONTAINER /etc/passwd --oio-account MY_ACCOUNT --oio-ns OPENIO
}

@test 'OIO - show object' {
  retry 10 1 docker exec -t "${SUT_ID}" openio container show MY_CONTAINER --oio-account MY_ACCOUNT --oio-ns OPENIO
}

@test 'OIO - list objects' {
  retry 10 1 docker exec -t "${SUT_ID}" openio object list --oio-account MY_ACCOUNT MY_CONTAINER --oio-ns OPENIO
}

@test 'OIO - Find the services involved for your container' {
  retry 10 1 docker exec -t "${SUT_ID}" openio container locate MY_CONTAINER --oio-account MY_ACCOUNT --oio-ns OPENIO
}

@test 'OIO - Consistency' {
  run docker exec -t "${SUT_ID}" bash -c 'md5sum /etc/passwd | cut -d" " -f1'
  assert_success
  md5orig="${output}"

  run docker exec -t "${SUT_ID}" bash -c "openio object list --oio-account MY_ACCOUNT MY_CONTAINER -c Hash -f value --oio-ns OPENIO|tr [A-Z] [a-z]"
  assert_success
  md5sds="${output}"

  assert_equal "$md5orig" "$md5sds"
}

@test 'OIO - Delete your object' {
  retry 10 1 docker exec -t "${SUT_ID}" openio object delete MY_CONTAINER passwd --oio-account MY_ACCOUNT --oio-ns OPENIO
}

@test 'OIO - Delete your empty container' {
  retry 10 1 docker exec -t "${SUT_ID}" openio container delete MY_CONTAINER --oio-account MY_ACCOUNT --oio-ns OPENIO
}

@test 'AWS - Get credentials' {
  retry 10 1 docker exec -t "${SUT_ID}" grep demo /root/.aws/credentials
}

@test 'AWS - create bucket' {
  retry 10 1 docker exec -t "${SUT_ID}" aws --endpoint-url "http://${SUT_IP}:6007" --no-verify-ssl s3 mb s3://mybucket
}

@test 'AWS - upload into bucket' {
  retry 10 1 docker exec -t "${SUT_ID}" aws --endpoint-url "http://${SUT_IP}:6007" --no-verify-ssl s3 cp /etc/passwd s3://mybucket
}

@test 'AWS - Consistency' {
  retry 10 1 docker exec -t "${SUT_ID}" bash -c 'md5sum /etc/passwd | cut -d" " -f1'
  assert_success
  md5orig="${output}"

  retry 10 1 docker exec -t "${SUT_ID}" aws --endpoint-url "http://${SUT_IP}:6007" --no-verify-ssl s3 cp s3://mybucket/passwd /tmp/passwd.aws
  assert_success

  retry 10 1 docker exec -i "${SUT_ID}" bash -c 'md5sum /tmp/passwd.aws | cut -d" " -f1'
  assert_success
  md5aws="${output}"

  assert_equal "$md5orig" "$md5aws"
}

@test 'AWS - Delete your object' {
  retry 10 1 docker exec -t "${SUT_ID}" aws --endpoint-url "http://${SUT_IP}:6007" --no-verify-ssl s3 rm s3://mybucket/passwd
}

@test 'AWS - Delete your empty bucket' {
  retry 10 1 docker exec -t "${SUT_ID}" aws --endpoint-url "http://${SUT_IP}:6007" --no-verify-ssl s3 rb s3://mybucket
}

@test 'OIO - Delete accounts' {
  retry 10 1 docker exec -t "${SUT_ID}" openio account delete MY_ACCOUNT --oio-ns OPENIO
  retry 10 1 docker exec -t "${SUT_ID}" openio account delete AUTH_demo --oio-ns OPENIO
}
