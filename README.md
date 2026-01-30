Update of vim-addon-actions, depending on NeoVim now
=====================================================
Allow to run graphs of tasks. Eg run compiler.

It allows to define graphs of tasks to be run in order as long as commands run
without error.

Special case run A B C, run_list({A, B, C})
Run and load quickfix, run_list({run_to_list({cmd}, {opts})})

Often you juggle multiple tools. See lua/nvim-actions2-demos.lua and its
mapping about how to quickly select a compiler option from a list of strings
allowing ` backtick expressions eg to inject current file to the action.

https://github.com/MarcWeber/vim-addon-errorformats allows to combine error
formats of multiple tools such as gcc rust gradle. So even meta tools are
supported easily.

So you can use this library with a local vimrc/init like file to get back your configurations.
Or you can define commonly used execution plans.

TODO: demos:
should expose all module functions so that run_list(..) is explicit and
defining graphs can be done. Should be trivial.

Example
=========
See lua/nvim-actions2-demos.lua


in your local vimrc

noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'./gradlew'}, {efm: vim.fn['vim_addon_errorformats#ForList']("clang"))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'./gradlew', 'installDebug'}, {efm: vim.fn['vim_addon_errorformats#ForList']('gradle clang java kotlin'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'ndk', '-t', 'arm64-v8a', '-o', 'app/src/main/jniLibs/', 'build'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust-errors-only'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'ndk', '-t', 'arm64-v8a', '-o', 'app/src/main/jniLibs/', 'build'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'apk', 'build'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust-errors-only'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'apk', 'run'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust-errors-only'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'build'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'run'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'run'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust-errors-only'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'build'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust-errors-only'))<CR>
noremap <silent> <F4> <Cmd>lua require('nvim-actions2').run_to_list({'cargo', 'build', '--release'}, {efm: vim.fn['vim_addon_errorformats#ForList']('rust'))<CR>


local map_efm_cmd_run = require('nvim-actions2').map_efm_cmd_run
map_efm_cmd_run('<F4>', 'error format names', {'zig', 'build'})
map_efm_cmd_run('<F5>', 'error format names', {command line args})


list = [[
efm_cmd_run('cpp', './gradlew')
efm_cmd_run('gradle clang java kotlin', {'./gradlew', 'installDebug'})
efm_cmd_run('rust-errors-only', {'cargo', 'ndk', '-t', 'arm64-v8a', '-o', 'app/src/main/jniLibs/', 'build'})
efm_cmd_run('rust', {'cargo', 'ndk', '-t', 'arm64-v8a', '-o', 'app/src/main/jniLibs/', 'build'})
efm_cmd_run('rust-errors-only', {'cargo', 'apk', 'build'})
efm_cmd_run('rust-errors-only', {'cargo', 'apk', 'run'})
efm_cmd_run('rust', {'cargo', 'build'})
efm_cmd_run('rust', {'cargo', 'run'})
efm_cmd_run('rust-errors-only', {'cargo', 'run'})
efm_cmd_run('rust-errors-only', {'cargo', 'build'})
efm_cmd_run('rust', {'cargo', 'build', '--release'})
]]

-> select line then run require('nvim-actions2').efm_cmd_run ?
KISS ?

lua require('nvim-actions2').run_list({'echo "a"', 'echo "b"'})
