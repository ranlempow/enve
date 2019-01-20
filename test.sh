#/bin/sh

dummy_runner_ok() {
    echo "1..3"
    echo "ok 1 dummy 1"
    echo "ok 2 dummy 2"
    echo "ok 3 dummy 3"
}

dummy_runner_bad() {
    echo "1..3"
    echo "ok 1 dummy 1"
    echo "not ok 2 dummy 2"
    echo "ok 3 dummy 3"
}


dummy_runner_"$1"

