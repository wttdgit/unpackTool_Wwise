rem 线程数修改Tools\thread.txt、建议3以内
for /f %%t in (Tools\thread.txt) do (set thread_count=%%t)
for /l %%i in (1,1,%thread_count%) do (rd /s /q Tools\Decoding_%%i)
del /q Tools\*_*.exe
del /q Tools\*_*.bat