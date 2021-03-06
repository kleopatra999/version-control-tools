#require hgmodocker

  $ . $TESTDIR/pylib/vcsreplicator/tests/helpers.sh
  $ vcsrenv

  $ pulse create-queue exchange/hgpushes/v1 all

Create a repository

  $ hgmo create-repo mozilla-central 1
  (recorded repository creation in replication log)
  $ standarduser

  $ hg -q clone ssh://${SSH_SERVER}:${SSH_PORT}/mozilla-central
  $ cd mozilla-central
  $ touch foo
  $ hg -q commit -A -m initial
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 1 changes to 1 files
  remote: recorded push in pushlog
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/mozilla-central/rev/77538e1ce4be
  remote: recorded changegroup in replication log in \d+\.\d+s (re)

  $ hgmo exec hgweb0 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ hgmo exec hgweb1 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ sleep 2
  $ pulseconsumer --wait-for-no-lag

  $ pulse dump-messages exchange/hgpushes/v1 all
  - _meta:
      exchange: exchange/hgpushes/v1
      routing_key: mozilla-central
    heads:
    - 77538e1ce4bec5f7aac58a7ceca2da0e38e90a72
    pushlog_pushes:
    - push_full_json_url: https://hg.mozilla.org/mozilla-central/json-pushes?version=2&full=1&startID=0&endID=1
      push_json_url: https://hg.mozilla.org/mozilla-central/json-pushes?version=2&startID=0&endID=1
      pushid: 1
      time: \d+ (re)
      user: user@example.com
    repo_url: https://hg.mozilla.org/mozilla-central

Repos under ignore paths are ignored

  $ cd ..
  $ hgmo create-repo private/ignore 1
  (recorded repository creation in replication log)
  $ hg -q clone ssh://${SSH_SERVER}:${SSH_PORT}/private/ignore
  $ cd ignore
  $ touch foo
  $ hg -q commit -A -m initial
  $ hg -q push

  $ hgmo exec hgweb0 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ hgmo exec hgweb1 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ sleep 2
  $ pulseconsumer --wait-for-no-lag

  $ hgmo exec hgssh grep private /var/log/pulsenotifier.log
  vcsreplicator.pushnotifications ignoring repo because path in ignore list: {moz}/private/ignore

  $ cd ..

Routing keys with slashes and dashes and underscores work

  $ hgmo create-repo integration/foo_Bar-baz 1
  (recorded repository creation in replication log)
  $ hg -q clone ssh://${SSH_SERVER}:${SSH_PORT}/integration/foo_Bar-baz
  $ cd foo_Bar-baz
  $ touch foo
  $ hg -q commit -A -m initial
  $ hg -q push

  $ hgmo exec hgweb0 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ hgmo exec hgweb1 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ sleep 2
  $ pulseconsumer --wait-for-no-lag

  $ pulse dump-messages exchange/hgpushes/v1 all
  - _meta:
      exchange: exchange/hgpushes/v1
      routing_key: integration/foo_Bar-baz
    heads:
    - 77538e1ce4bec5f7aac58a7ceca2da0e38e90a72
    pushlog_pushes:
    - push_full_json_url: https://hg.mozilla.org/integration/foo_Bar-baz/json-pushes?version=2&full=1&startID=0&endID=1
      push_json_url: https://hg.mozilla.org/integration/foo_Bar-baz/json-pushes?version=2&startID=0&endID=1
      pushid: 1
      time: \d+ (re)
      user: user@example.com
    repo_url: https://hg.mozilla.org/integration/foo_Bar-baz

Cleanup

  $ hgmo clean
