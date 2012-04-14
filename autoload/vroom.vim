" Init
if exists("g:loaded_vroom") || &cp
  finish
endif
let g:loaded_vroom = 1

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

" Public: Run current test file, or last test run
function vroom#RunTestFile()
  call s:RunTestFile()
endfunction

" Public: Run the nearest test in the current test file
" Assumes your test framework supports filename:line# format
function vroom#RunNearestTest()
  call s:RunNearestTest()
endfunction

" Internal: Runs the current file as a test. Also saves the current file, so
" next time the function is called in a non-test file, it runs the last test
"
" suffix - An optional command suffix
function s:RunTestFile(...)
  if a:0
    let command_suffix = a:1
  else
    let command_suffix = ""
  endif

  " Run the tests for the previously-marked file.
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\|_test.rb\)$') != -1

  if in_test_file
    call s:SetTestFile()
  elseif !exists("t:vroom_test_file")
    return
  end
  call s:RunTests(t:vroom_test_file . command_suffix)
endfunction

" Internal: Runs the current or last test with the currently selected line
" number
function s:RunNearestTest()
  let spec_line_number = line('.')
  call s:RunTestFile(":" . spec_line_number)
endfunction

" Internal: Runs the test for a given filename
function s:RunTests(filename)
  call s:ClearScreen()
  call s:WriteOrWriteAll()
  call s:CheckForGemfile()
  call s:SetColorFlag()
  " Run the right test for the given file
  if match(a:filename, '_spec.rb') != -1
    exec ":!" . s:bundle_exec ."rspec " . a:filename . s:color_flag
  elseif match(a:filename, '\.feature') != -1
    exec ":!" . s:bundle_exec .g:vroom_cucumber_path . a:filename . s:color_flag
  elseif match(a:filename, "_test.rb") != -1
    exec ":!" . s:bundle_exec ."ruby -Itest " . a:filename
  end
endfunction

" Internal: Clear the screen prior to running specs
function s:ClearScreen()
  if g:vroom_clear_screen
    :silent !clear
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

" Internal: Checks for Gemfile, and sets s:bundle_exec as necessary
function s:CheckForGemfile()
  if s:GemfileExists()
    let s:bundle_exec = "bundle exec "
  else
    let s:bundle_exec = ""
  endif
endfunction

" Internal: Checks for 'spec_helper' in file and Gemfile existance, and sets
"           s:bundle_execs as necessary
function s:CheckForSpecHelper(filename)
  if g:vroom_detect_spec_helper &&
        \match(readfile(a:filename, '', 1)[0], 'spec_helper') != -1 &&
        \s:GemfileExists()
    let s:bundle_exec = "bundle exec "
  else
    let s:bundle_exec = ""
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

" Internal: Sets s:color_flag to the correct color flag as configured
function s:SetColorFlag()
  if g:vroom_use_colors
    let s:color_flag = " --color"
  else
    let s:color_flag = " --no-color"
  endif
endfunction
