function topology = US_Backbone()
%bone_topo=US_Backbone();
% 输入：无
% 输出：bone_topo：US_Backbone拓补的邻接矩阵信息

topology =[

   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
     1   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf     1   Inf   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
     1   Inf   Inf   Inf   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf     1     1   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1     1;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf

];

end