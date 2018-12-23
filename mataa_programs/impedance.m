% script for impedance measurements


% sample rate:
if ~exist('fs','var')
	fs = input ('Enter sampling rate (Hz): ')
end
disp (sprintf('Sampling rate = %g Hz',fs))

% sine sweep:
if ~exist('fL','var')
	fL = input ('Sine sweep start frequency (Hz): ')
end
disp (sprintf('Sine sweep start frequency = %g Hz',fL))

if ~exist('fH','var')
	fH = input ('Sine sweep end frequency (Hz): ')
end
fH = min([fs/2,fH]);
disp (sprintf('Sine sweep end frequency = %g Hz',fH))

if ~exist('U0','var')
	U0 = input ('Sine sweep amplitude (V-RMS): ')
end
disp (sprintf('Sine sweep amplitude = %g V-RMS',U0))

% reference resistor:
if ~exist('R0','var')
	R0 = input ('Enter reference resistor value (Ohm): ')
end
disp (sprintf('Reference resistor = %g Ohm',R0))

% SPL smoothing / resolution:
if ~exist('res','var')
	res = input ('Impedance curve smoothing (octave-fraction): ');
end
if isempty(res)
	disp ('No smoothing')
else
	disp (sprintf('Impedance curve smoothing = 1/%i octave',res))
	res = 1/res;
end

% Plot color:
if ~exist('col','var')
	col = input ('Plot color (char: k, r, g, b, c, m, y): ','s');
end
if isempty ('col')
	col = 'r';
end
disp (sprintf('Plot color = %s',col))
style = sprintf('%s-',col);

% calibration file:
calfile = 'MB_ELECTRONIC_CHAIN.txt';
disp (sprintf('Calibration file = %s',calfile))

% Ready? Input ok?
input ('Ready to start? Press ENTER...')

% impedance measurement:
[Zmag,Zphase,f] = mataa_measure_impedance (fL,fH,R0,fs,res,calfile,U0*sqrt(2),'V');

% plot result:
semilogx (f,Zmag,style)


% always save to "LastMeasurement.mat":
save ('-V7','LastMeasurementIMP.mat','f','Zmag','Zphase','fL','fH','R0','fs','res','calfile','U0');

% Ask to save file:
x = input ('Do you want to save raw data to a file (y/N)?','s');
if isempty(x)
	x = 'N';
end
if upper(x) == 'Y'
	fn = uiputfile('*.mat','Choose file to save raw data...');
	if ischar(fn)
		info = input ('Enter data description: ','s')
		save ('-V7',fn,'f','Zmag','Zphase','fL','fH','R0','fs','res','calfile','U0','info');
		disp (sprintf('Saved data to file %s.',fn));
	else
		disp ('File not saved.')
	end
end
