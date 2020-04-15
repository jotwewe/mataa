% function mataa_build_TestTonePA19_oct
% 
% DESCRIPTION:
% Call this function to build the oct file for mataa_playrecord_pa19, which enables 
% fast audio output and input.
% 
% DISCLAIMER:
% This file is part of MATAA.
% 
% MATAA is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
% 
% MATAA is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with MATAA; if not, write to the Free Software
% Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
% 
% Copyright (C) 2020 Jens W. Wulf.
function mataa_build_TestTonePA19_oct()
  clear mataa_playrecord_pa19;
  strPath = pwd();
  cd(mataa_path('main'))
  cd('TestTone/oct_PA19')
  mkoctfile -L/usr/lib/x86_64-linux-gnu -lportaudio -lm -lrt -lasound -lpthread -o mataa_playrecord_pa19.oct TestTonePA19_oct.cpp
  cd(strPath)  
  octpath = [mataa_path('main') 'TestTone/oct_PA19'];
  addpath(octpath)
  
  if exist('mataa_playrecord_pa19')
    fprintf(stdout(), "mataa_playrecord_pa19 is available.\n");
    fprintf(stdout(), "Please add\naddpath('%s')\nto your .octaverc or mataa startup script.\n", octpath)
  else
    fprintf(stdout(), "mataa_playrecord_pa19 is not available.\n");
  end
end
