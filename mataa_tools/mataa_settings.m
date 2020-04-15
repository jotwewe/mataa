function val = mataa_settings (field,value)

% function val = mataa_settings (field,value)
%
% DESCRIPTION:
% Retrieve and set MATAA settings.
%
% mataa_settings with no arguments returns all the settings
% mataa_settings(field) returns the value of the setting of 'field'
% mataa_settings(field,val) sets the value of the setting 'field' to 'val'.
% mataa_settings('reset') resets the settings to default values
%
% EXAMPLES:
% ** get the current settings (this also shows you the available fields):
% > mataa_settings
%
% ** get the current plot color:
% > mataa_settings('plotColor')
%
% ** set the plot color to red:
% > mataa_settings('plotColor','r')
%
% ** In principle, you can store anything in the MATAA settings file. For instance, you can store the birhtday of your grandmother, so you'll never forget that:
% > mataa_settings('BirthdayOfMyGrandmother','1st of April 1925');
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
% Copyright (C) 2006, 2007, 2008 Matthias S. Brennwald.
% Contact: info@audioroot.net
% Further information: http://www.audioroot.net/MATAA

path = mataa_path ('settings');
path = sprintf('%s.mataa_settings.mat',path);

reset_to_def = ~exist(path,'file');

if (~reset_to_def && exist('field','var')) reset_to_def = strcmp(field,'reset'); end

  % Define default settings:
  defaultsettings.plotColor = 'b';
  
  % More than 1 looks better on modern devices, but octave+gnuplot slows down painfully:
  defaultsettings.plot_linewidth = 1;
  
  % Use one of north, northwest, west, southwest, south, ...:
  defaultsettings.plot_legendpos_mag = "south";
    
  %% DEPRECATED: defaultsettings.microphone = 'unknown_microphone';
  defaultsettings.plotWindow_IR = 1;
  defaultsettings.plotWindow_SR = 2;
  defaultsettings.plotWindow_FR = 3;
  defaultsettings.plotWindow_CSD = 4;
  defaultsettings.plotWindow_ETC = 5;
  defaultsettings.plotWindow_HD = 6;
  defaultsettings.plotWindow_impedance = 7;
  defaultsettings.plotWindow_TBES = 8;
  defaultsettings.openPlotAfterSafe = 1;
  
  defaultsettings.channel_DUT = 1;
  defaultsettings.channel_REF = 2;
  
  defaultsettings.interchannel_delay = 0;
  
  % don't run the TestDevices check and return generic audio info instead (suitable 
  % for a typical audio interface, stereo, full duplex). This is useful to skip the 
  % query to audio interfaces which do nasty things when TestDevices asks them for
  % their properties (such as the RTX-6001 which goes crazy with relays clicking) or 
  % to simply save time.
  defaultsettings.audioinfo_skipcheck = 0; 
  
  % Set to 0.0001 in case of output problems (I needed it with:
  % PC -> USB -> optical S/PDIF -> Sony STR-DE485E). Does not cause problems in 
  % other cases, therefore becomes default.
  defaultsettings.padding_level = 0.0001;
  
  % Duration to pad test signals at beginning and end. Increase this value if you
  % experience truncated signals.
  % mataa_ - functions don't use this value but an argument specifying it. The author
  % of the raa_ - functions assumes that most users will be fine with a preset they
  % can change in case of specific hardware.
  defaultsettings.padding_duration = 0.2;

if reset_to_def
	% create / reset to default settings:
	mataa_settings = defaultsettings;
	
	cc = [ 'save -mat ' path ' mataa_settings ; ' ];
	disp(sprintf('Creating / resetting to MATAA default settings (command: %s)...',cc));
	eval( cc );
	val = mataa_settings;
	disp(mataa_settings);
	disp('...done.');
end

% load settings from disk:
load(path);

% Default values for settings added in later versions:
cFN = fieldnames(defaultsettings);
for n=1:length(cFN)
  if isfield(mataa_settings, cFN{n}) == 0
    mataa_settings.(cFN{n}) = defaultsettings.(cFN{n});
  end
end

if nargin==0 % return all settings
	val = mataa_settings;	
	return
else
	if nargin == 1 % read and return the value of the specified field
		if isfield(mataa_settings,field)
			eval( ['val = mataa_settings.' field ';' ] );
		else
			warning(sprintf('mataa_settings: Unknown field value in mataa_settings: %s.',field));
			val = [];
		end		
	elseif nargin == 2 % set the field to the specified value and save the settings file	
		eval( [ 'mataa_settings.' field ' = value ; ' ] );
		eval( [ 'save -mat ' path ' mataa_settings ; ' ] );
		val = value;
	
	else
		warning('Too many input arguments for mataa_settings.');
	end

end

	
	
