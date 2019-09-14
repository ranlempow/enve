
# 整體架構

boot - 檢查和建立基礎環境(boot.cmd)
enve - 鎖鏈式執行環境封裝/更友善的terminal&shell
pm - 發布管理, 配置管理, 行程管理
ci - 持續整合系統, 自動化測試與回報
gitu - 簡化git操作, 實現gitflow, 多使用者流程

nix-installer
service-setup

fs-plugin       協助分配與掛載檔案系統
(X)env-plugin      協助引入其他依賴
(X)build-plugin    協助簡化建造流程


# 目錄結構

/bin - 可供使用者直接執行的程式
/libexec - 內部程式或模組, 進階使用者可以低階執行
/libexec/enve/contrib/
/libexec/enve/builtins/
/libexec/enve/thirdparty/
/libexec/pm/
/libexec/ci/

/test
/docs - 所有非正式的文件
/man - 正式的說明手冊
/tools - 專案維護用的腳本(?)
.gitattributes
README.md


# 模組

模組本身是一個enve可執行環境
根據被fire時所使用的角色, 可以執行不同的功能

core/           內建模組, 官方維護, 相容性保證, 品質保證, 使用時可以省略core/, 會依照TABLE而被自動引入
contrib/        內建模組, 貢獻者維護, 使用時可以省略contrib/
thirdparty/     需下載模組, 因複雜度過高, 需要編譯, 過於龐大, 或是更新太快, 而放在外部的源碼庫, 但是仍被官方信任



零件替換理論

ab  Ab  aB  AB
X   X   X   X   a與A損毀 或 b與B損毀
O   X   X   X   A與B損毀
O   O   X   X   B損毀
O   O   O   X   A或B損毀, 也有可能只有AB這個組合損毀

abc Abc aBc abC ABc AbC aBC ABC
O   X   X   X   X   X   X   X   A與B與C損毀
O   O   X   X   X   X   X   X   B與C損毀
O   O   O   X   O   X   X   X   C損毀
O   O   O   O   O   O   X   X   C損毀, 也有可能只有BC這個組合損毀



如果config只依賴
1. 專案資料夾裡面的檔案, 除非用bound.ignore排除
2. 版本化的 enve core module
3. pure outside module
4. 也就是要版本化任何外部依賴, 包含npm, pyvenv, ruby, cocospods
那我們可以說這個config是pure config


pure config可以建構pure environment
pure environment再加上只限於專案資料夾來源的build, 可以build出 pure installable
pure installable -> pure runtime -> pure test

                    unpure develop-env
pure source       -> pure build-env          1..*  pure installable      extra-build-config
pure installable  -> pure installable-env    1..*  pure runtime          extra-install-config
pure installed    -> pure runtime-env        1..*  pure test             extra-run-config


roles 可以作為決定變種的橋樑
source_path@build@build-cfg-1@install-cfg-B@run-cfg-alpha


每一個runtime都有一個版本標誌, 標誌裡多個stage, 目前有build, install, run, 三個stage
每個stage內有下列內容
1. source 可以連結到上個stage
2. env 與他的依賴 modules, 每個module都是一個runtime
3. roles
4. extra-configs
這些組合起的標誌用來代表一個軟體的出身, 是debug的時候非常重要的資訊


用資料夾結構來表示如下
$runtime_stage/
$stage/input/source(version+commit_time|parent) -> stage Class
$stage/input/maker                              -> stage Class
$stage/env-modules/$mod_runtime/                -> runtime Class(stage class)
$stage/env (roles, conifg, timestamp, kernel-version, machine, system-info, invocation-id)

stage_name = $program-$version-(build|install|run|config)-$stage_hash

用keyvalue config來表達stages
[$stage_name]
$key=$value




# Module Resolve Process

Project Table Analyzing Phase
-----------------------------
fire core.loader.enve environment with "loader" role and "loader" target.
loader should take care "Source URL Resolve Phase" also

input: project table (pure), loaders (pure)
output: url (maybe pure), config table (pure)


Source URL Resolve Phase
------------------------
locate module source code to a directory.
maybe needs git operations, web download or unpack a compressed file.

input: url (maybe pure)
output: source_dir (maybe pure)


Module Deploy Phase
-------------------
maybe the module source needs build.
the extra build configure may set by "$module.build".

after built, the module artifact maybe needs install.
the extra install configure may set by "$module.install".

input(hashed): source_dir (maybe pure), config table (pure)
output(hashed): module_dir (pure)


Module Execute Phase
--------------------
in final deployed directory.
fire enve.ini environment with "module" role and "module" target.
callee execution should accept caller CONFIG_TABLE from stdin
and generate MOD_CONFIG_TABLE to stdout.
caller environment should merge that MOD_CONFIG_TABLE to caller CONFIG_TABLE.

input: project table (pure), $module_dir/module.enve (pure, hashed)
output: table (pure)



# Functional representation

parse_config(files[NONE_PURE], keyvalues, roles, project_abs_path) -> CONFIG_TABLE
load_modules(CONFIG_TABLE) -> module_paths
resolve(module_paths, CONFIG_TABLE) -> ENV_TABLE


gen_rcfile_runner(ENV_TABLE) -> rcfile_runner
gen_rcfile_shell(ENV_TABLE, $shell) -> rcfile_$shell (combine with rcfile_runner)



# build config
resolve(parse_config(..., roles=build, project_abs_path)) -> ENV_TABLE_BUILD
gen_rcfile_runner(ENV_TABLE_BUILD) -> build_rcfile_runner
build_rcfile_runner build -> pkg_dir

# partial run config
resolve(parse_config(..., roles=run, project_abs_path=pkg_dir)) -> ENV_TABLE_RUN
extact_env_files(ENV_TABLE_RUN) -> run_env_files
gen_rcfile_runner(ENV_TABLE_RUN) -> rcfile_runner
global_paths = pkg_dir + run_env_files + rcfile_runner

# deploy config
deploy([global_paths]+, deploy_config, run_config)




# config

var.bypass - 執行時引入環境變數
var.memory - 紀錄建造時的環境變數

build.xxx

run.setup_cmd[list] - 進入環境之前最後的bash調整命令
run.chain_cmd[list] - 進入環境時呼叫的前置命令列




# gen_rcfile_run(ENV_TABLE, run_command) -> rcfile
# gen_rcfile_shell(ENV_TABLE, run_command) -> rcfile
# run(ENV_TABLE, run_command) -> NONE_PURE
# shell(ENV_TABLE, run_command) -> NONE_PURE


gen_rcfile_build(ENV_TABLE) -> rcfile
build_new(ENV_TABLE, src) -> build_result_dir
build_fixing_location(ENV_TABLE, src) -> NONE_PURE
build_installable(ENV_TABLE, src) -> $build_result_dir/enve.ini

install_new[$build_result_dir/enve.ini](INSTALLABLE_ENV_TABLE, build_result_dir) -> installed_result_dir
install_specific(INSTALLABLE_ENV_TABLE, build_result_dir) -> NONE_PURE
install_runable(INSTALLABLE_ENV_TABLE, build_result_dir) -> $run_result_dir/enve.ini

deploy(deploy_list, INSTALLABLE_ENV_TABLE, build_result_dir) -> NONE_PURE
deploy_transform(deploy_dest, INSTALLABLE_ENV_TABLE, build_result_dir) -> $prepare_to_depoly/enve.ini



# NEW DEFINE

fire = ( loadconfig | (firechain $module + resolve)* | gen_rcfile ) + target_exec "$@"
firechain = (fire $target)* + fire final_target "$@"
enve_main = crossplat_bootenv + parse_args + firechain


# bootstrap process

check what is the os we are running "$(system_roles)"

basic_require_ensure
    install basic tools if not exist
    Darwin: no
    Linux: pacman -S curl git openssh
    FreeBSD: pkg install curl git bash
    Msys2: pacman -S git openssh

parse_args
    -> reexec_if_reqver_not_match

