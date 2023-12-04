"V2 by Max.231204" ；  
改成python就快了很，几乎都是内置库，所以没有require.txt；最终会自动新建并导出到".\ogg"文件夹；  
处理过的input文件会添加.done后缀（方便'断点续转')；  
即便_ren(ame)Back(.bat)回原始文件名、只要在".\ogg"文件夹存在同名ogg文件、也会跳过对同名wem的重复转码（方便'断点续转'）；  
说实话pck和bnk都很快、但wem量大还转码2次就很慢、所以能略就略  

"V1 by Max.231130" ；  
线程数修改Tools\thread.txt、默认33 ；  
多线程针对动辄上万的wem资源提升unpack效率  
