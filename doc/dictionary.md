
TODO:
1.利用註解說明gitignore_filter與gitignore實作上不相符的部分
2.(O)廣泛使用table_substi
3.(X)include指令移到前期resolve執行, loadconfig因為不用遞迴而更加清淨
4.(X)將pm整合入enve, 也就是說pm只是enve一個小外掛, ci也是enve小外掛
  但是pm利用enve來做大部分的invoke工作

5.(O)注意passvar與subsitution個關係, (X)passvar應該是不能影響subsitution
  (O)passvar內所指定的變數, 會讓subsitution改用escape的方式遷入rcfile

6.(O)'key='這樣的形式是unset, unset就是false, LIST也會因為這樣而被全部unset
7.(O)bool型別 true,false,unset(assign default value)


API作法
------
* Lib API: 每個原始碼分開介紹
* configs: 每個功能或模組分成章節, 一次介紹一組功能相近的configs
* CLI tools: 目前只有enve需要介紹


版本作法
------
每1-4年一次大改版, 架構更變, API大量更變, 廢棄config
每2-12個禮拜一次小改版, 新的機能加入, API少量更變, 主要是增加新的config



enve.bound          extra bound file
enve.bound.ignore   bound file ignore role, use gitignore format
enve.bound.git      default is true, if true, use .gitignore at $PRJROOT and ignore git


enve.base.native    default is true, if false, use nix-env as base env
enve.base.version   if set, switch to specific version
enve.base.shell     if set, switch to specific shell


enve.require
enve.require.version    make enve executable in subenv

## 模組module
define.module                           模組定義
define.module.$i.name     default is "$dirname"/*.enve.ini
define.module.$i.produce  must set
define.module.$i.native_exec
        default is false, no create enve
define.module.$i.source_exec
        default is false, not use fork, use '.' instand
define.module.$i.exec     default is %root/$procedure.enve.module
(X)define.module.$i.order    must set
define.module.$i.after    this may help ordering modules
define.module.$i.before


core.target

enve.target

enve.build          type of build target, default is none, options are
                    [none|package|build]
                    build會進行建造但是不打包, 輸出可以下則%path|%cache|%tmp
                    package會把build之後的資料夾進行打包, 輸出放到cache

enve.setup          type of setup target, default is none, options are
                    [none|chroot|simple|tmp]
                    none是直接使用原始碼資料夾, 跳過任何設定步驟
                    chroot會設定一個可以被chroot的系統資料夾
                    simple只是簡單的初始化一個空的資料夾
                    tmp比simple更單純, 而且使用暫存茲要夾

layout.root
layout.tmp
layout.out
layout.var
layout.cache



path - PATH
passvar
dotfiles
alias.*
variable.*  subsitution only
environ.*   subsitution and environ variable
envfile
cmd.*
shell
cwd         default is %keep

shell.zsh


terminal.size
terminal.theme

(X)enve.no_nix
nix.enable(BOOL-true)
nix.channel.url
nix.channel.version
nix.packages
nix.root
nix.files
nix.config

comment

include(LIST)
inherit             like include, but use inherit config as layout.root


(X)module.import(LIST)
module(LIST)
module.$name.path
module.param.*
module.roles(LIST)



build.out           artifact output path, default is %cache
build.exec          default is %autodetect
build.refresh       force rebuild
build.package       make tar file, default is %nopkg, %cache|%tmp|%nopkg|[path]



install.root
install.exec

install.files
install.files.[name].variable
install.files.[name].content
install.files.[name].source
install.files.[name].path
install.files.[name].mode

install.unpack
install.unpack.[name].variable
install.unpack.[name].source
install.unpack.[name].path
install.unpack.[name].mode


(X)install.download
(X)install.download.source
(X)install.download.path



(O)system.path - chroot path
(O)system.template - copy file to chroot path
(O)system.bin - ',' split list, add program at host to chroot path

(O)system.jail - use advance isolation technology

(F)system.interface - add interface at host to jail
(O)system.mount - given as a single fstab(5) line, mount to chroot path
                - there are nixdir, cachedir, tmpdir mounts by default

settle.* <- system.*


piso.exec.*

(O)exec.start
exec.command - replace exec.start

exec.use_sudo
(O)exec.clean
exec.passenv
exec.unsetenv - 'env -u XXX'
(O)exec.user
(F)exec.invoke_user
(O)exec.cwd
(O)exec.stdin
(O)exec.stdout
(O)exec.stderr
(O)exec.umask
exec.ulimit.XXX
exec.env.XXX
exec.pidfile - assume exec.start should do the fork stuff
exec.daemon - detach form currnet shell, fork twice and new session
            - default to true if invoke by pm, default to false if invoke by enve

pm.socket - communicate path of sub-pm

test.jobs.*
test.jobs.*.parallel        default true, if false, must run by order
                            and mutually exclusive
test.sets.*.branches        test commits on branch
test.sets.*.roles
test.sets.*.limit           test only recent commits by limit number
test.sets.*.after           test commits after that date


build.exec
test.exec
ci

