" Init {{{

if exists("g:loaded_vroom") || &cp
  finish
endif
let g:loaded_vroom = 1

if !exists("g:vroom_spec_command")
  let g:vroom_spec_command = 'rspec '
endif

if !exists("g:vroom_use_colors")
  let g:vroom_use_colors = !has('gui_running')
endif

if !exists("g:vroom_clear_screen")
  let g:vroom_clear_screen = 1
endif

if !exists("g:vroom_write_all")
  let g:vroom_write_all = 0
endif

if !exists("g:vroom_cucumber_path")
  let g:vroom_cucumber_path = './script/cucumber '
endif

if !exists("g:vroom_detect_spec_helper")
  let g:vroom_detect_spec_helper = 0
endif

if !exists("g:vroom_use_vimux")
  let g:vroom_use_vimux = 0
endif

if !exists("g:vroom_use_dispatch")
  let g:vroom_use_dispatch = 0
endif

if !exists("g:vroom_use_bundle_exec")
  let g:vroom_use_bundle_exec = 1
endif

if !exists("g:vroom_use_spring")
  let g:vroom_use_spring = 0
endif

" If we are using binstubs, we usually don't want to bundle exec.  Note that
" this has to come before the g:vroom_use_binstubs variable is set below.
if exists("g:vroom_use_binstubs")
  let g:vroom_use_bundle_exec = 0
endif

" Binstubs aren't used by default
if !exists("g:vroom_use_binstubs")
  let g:vroom_use_binstubs = 0
endif

if !exists("g:vroom_binstubs_path")
  let g:vroom_binstubs_path = './bin'
endif

if !exists("g:vroom_test_unit_command")
  let g:vroom_test_unit_command = 'ruby -Itest '
endif

if !exists("g:vroom_rspec_version")
  let g:vroom_rspec_version = '2.x'
endif

if !exists("g:vroom_use_zeus")
  let g:vroom_use_zeus = 1
endif

" }}}
" Main functions {{{

" Public: Run current test file, or last test run
"
" args     - options for running the tests:
"            'runner': the test runner to use (e.g., 'm')
"            'options': any additional options (e.g., '--drb')
function vroom#RunTestFile(...)
  if a:0
    let opts = a:1
  else
    let opts = {}
  endif

  call s:RunTestFile(opts)
endfunction

" Public: Run the nearest test in the current test file
" Assumes your test framework supports filename:line# format
"
" args     - options for running the tests:
"            'runner': the test runner to use (e.g., 'm')
"            'options': any additional options (e.g., '--drb')
function vroom#RunNearestTest(...)
  if a:0
    let opts = a:1
  else
    let opts = {}
  endif

  call s:RunNearestTest(opts)
endfunction

" }}}
" Internal helper functions {{{

" Internal: Runs the current file as a test. Also saves the current file, so
" next time the function is called in a non-test file, it runs the last test
function s:RunTestFile(args)
  " Run the tests for the previously-marked file.
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\|_test.rb\)$') != -1

  if in_test_file
    call s:SetTestFile()
  elseif !exists("t:vroom_test_file")
    return
  end

  call s:RunTests(t:vroom_test_file, a:args)
endfunction

" Internal: Runs the current or last test with the currently selected line
" number
function s:RunNearestTest(args)
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\|_test.rb\)$') != -1

  if in_test_file
    call s:SetNearestTest()
  elseif !exists("t:vroom_nearest_test")
    return
  end

  let test_line = ':' . t:vroom_nearest_test
  let updated_args = s:Merge(a:args, {'line':test_line})

  call s:RunTestFile(updated_args)
endfunction

" Internal: Runs the test for a given file.
"
" filename - a filename.
" args     - options for running the tests:
"            'runner': the test runner to use (e.g., 'm')
"            'options': any additional options (e.g., '--drb')
"            'line_number': the line number of the test to run (e.g., ':4')
function s:RunTests(filename, args)
  call s:PrepareToRunTests(a:filename)

  let runner        = get(a:args, 'runner', s:DetermineRunner(a:filename))
  let opts          = get(a:args, 'options', ''                          )
  let line_number   = get(a:args, 'line',    ''                          )

  call s:Run(runner . ' ' . opts . ' ' . a:filename . line_number)
endfunction

" Internal: Get the right test runner for the file.
function s:DetermineRunner(filename)
  if match(a:filename, '_spec.rb') != -1
    return s:test_runner_prefix . g:vroom_spec_command . s:color_flag
  elseif match(a:filename, '\.feature') != -1
    return s:test_runner_prefix . g:vroom_cucumber_path . s:color_flag
  elseif match(a:filename, "_test.rb") != -1
    return s:test_runner_prefix . g:vroom_test_unit_command
  end
endfunction

" Internal: Perform all the steps we need to perform before actually running
" the tests: clear the screen, write the files, set the test_runner_prefix,
" set the color_flag.
function s:PrepareToRunTests(filename)
  if g:vroom_clear_screen
    call s:ClearScreen()
  endif
  call s:WriteOrWriteAll()
  call s:SetTestRunnerPrefix(a:filename)
  if s:usingZeus()
    let s:color_flag = ""
  else
    call s:SetColorFlag()
  endif
endfunction

" Internal: Runs a command though vim or vmux
function s:Run(cmd)
  if g:vroom_use_vimux
    call VimuxRunCommand(a:cmd)
  elseif g:vroom_use_dispatch && exists(':Dispatch')
    exec ":Dispatch " . a:cmd
  else
    exec ":!" . a:cmd
  end
endfunction

" Internal: Clear the screen prior to running specs for vimux
" Otherwise, prefix the command with a clear.
function s:ClearScreen()
  if g:vroom_use_vimux
    call VimuxRunCommand("clear")
  endif
endfunction

" Internal: Write or write all files
function s:WriteOrWriteAll()
  if g:vroom_write_all
    :wall
  else
    :w
  endif
endfunction

" Internal: Merge a pair of dictionaries non-destructively.
"
" dictionary1 - the dictionary that is to be merged into.
" dictionary2 - the dictionary that is to be merged in.
"
" Returns a dictionary.
function s:Merge(dictionary1, dictionary2)
  let dictionary = {}
  call extend(dictionary, a:dictionary1)
  call extend(dictionary, a:dictionary2)

  return dictionary
endfunction

" }}}
" Settings (functions to determine) {{{

" Internal: Set s:test_runner_prefix variable
function s:SetTestRunnerPrefix(filename)
  let s:test_runner_prefix = ''
  call s:IsUsingZeus()
  call s:IsUsingBundleExec(a:filename)
  call s:IsUsingBinstubs()
  call s:IsUsingSpring()
  call s:IsClearScreenEnabled()
endfunction

" Internal: Check for .zeus.sock and use zeus instead of bundler
function s:IsUsingZeus()
  if s:usingZeus()
    if !exists("s:vroom_use_bundle_exec_original")
      let s:vroom_use_bundle_exec_original = g:vroom_use_bundle_exec
    endif
    let g:vroom_use_bundle_exec = 0

    let s:test_runner_prefix = "zeus "
  else
    if exists("s:vroom_use_bundle_exec_original")
      let g:vroom_use_bundle_exec = s:vroom_use_bundle_exec_original
    endif
  endif
endfunction

" Internal: Using Zeus ?
function s:usingZeus()
  if g:vroom_use_zeus && glob(".zeus.sock") != ""
    return 1
  else
    return 0
  endif
endfunction


" Internal: Check for a Gemfile if we are using `bundle exec`
function s:IsUsingBundleExec(filename)
  if g:vroom_use_bundle_exec
    if g:vroom_detect_spec_helper
      call s:CheckForSpecHelper(a:filename)
    else
      call s:CheckForGemfile()
    endif
  endif
endfunction

" Internal: Set s:test_runner_prefix variable if using binstubs
function s:IsUsingBinstubs()
  if g:vroom_use_binstubs
    let s:test_runner_prefix = g:vroom_binstubs_path . '/'
  endif
endfunction

" Internal: Set s:test_runner_prefix variable if using spring
function s:IsUsingSpring()
  if g:vroom_use_spring
    let s:test_runner_prefix = "spring "
  endif
endfunction

" Internal: Check to see if we should clear the screen and prefixes
"           s:test_runner_prefix as neessary
function s:IsClearScreenEnabled()
  if g:vroom_clear_screen && !g:vroom_use_vimux
    let s:test_runner_prefix = "clear; " . s:test_runner_prefix
  endif
endfunction

" Internal: Checks for Gemfile, and sets s:test_runner_prefix as necessary
function s:CheckForGemfile()
  if s:GemfileExists()
    let s:test_runner_prefix = "bundle exec "
  endif
endfunction

" Internal: Checks for 'spec_helper' in file and Gemfile existance, and sets
"           s:test_runner_prefixs as necessary
function s:CheckForSpecHelper(filename)
  if g:vroom_detect_spec_helper &&
        \match(readfile(a:filename, '', 1)[0], 'spec_helper') != -1 &&
        \s:GemfileExists()
    let s:test_runner_prefix = "bundle exec "
  else
    let s:test_runner_prefix = ""
  endif
endfunction

" Internal: Check if there is a Gemfile in the current working directory
function s:GemfileExists()
  if filereadable("Gemfile")
    return 1
  else
    return 0
  endif
endfunction

" Internal: Sets t:vroom_test_file to current file
function s:SetTestFile()
  " Set the test file that tests will be run for.
  let t:vroom_test_file=@%
endfunction

" Internal: Sets t:vroom_nearest_test to current line
function s:SetNearestTest()
  let t:vroom_nearest_test = line('.')
endfunction

" Internal: Sets s:color_flag to the correct color flag as configured
function s:SetColorFlag()
  if g:vroom_rspec_version == "2.x"
    if g:vroom_use_colors
      let s:color_flag = " --color"
    else
      let s:color_flag = " --no-color"
    endif
  else
    if g:vroom_use_colors
      let s:color_flag = " --color"
    else
      let s:color_flag = ""
    endif
  endif

endfunction

" }}}
