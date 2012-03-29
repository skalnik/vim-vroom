function! s:RunTestFile(...)
  if a:0
    let command_suffix = a:1
  else
    let command_suffix = ""
  endif

  " Run the tests for the previously-marked file.
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\|_test.rb\)$') != -1

  if in_test_file
    call s:SetTestFile()
  elseif !exists("s:smh_test_file")
    return
  end
  call s:RunTests(s:smh_test_file . command_suffix)
endfunction

function! s:RunNearestTest()
  let spec_line_number = line('.')
  call s:RunTestFile(":" . spec_line_number)
endfunction

function! s:RunTests(filename)
  :w " Write the file
  call s:CheckForGemfile()
  " Run the right test for the given file
  if match(a:filename, '_spec.rb') != -1
    exec ":!" . s:bundle_exec ." rspec " . a:filename . " --no-color"
  elseif match(a:filename, '\.feature') != -1
    exec ":!" . s:bundle_exec ." script/features " . a:filename
  elseif match(a:filename, "_test.rb") != -1
    exec ":!" . s:bundle_exec ." bundle exec ruby -Itest " . a:filename
  end
endfunction

function! s:CheckForGemfile()
  if filereadable("Gemfile")
    let s:bundle_exec = "bundle exec"
  else
    let s:bundle_exec = ""
  endif
endfunction

function! s:SetTestFile()
  " Set the test file that tests will be run for.
  let s:smh_test_file=@%
endfunction

" Available for Autoload
function! vroom#RunTestFile()
  call s:RunTestFile()
endfunction

function! vroom#RunNearestTest()
  call s:RunNearestTest()
endfunction
