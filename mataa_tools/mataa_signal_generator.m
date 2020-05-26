function [s,t,info] = mataa_signal_generator (kind,fs,T,param, param2)

% function [s,t,info] = mataa_signal_generator (kind, fs, T, param)
% function [s,t,info] = mataa_signal_generator ('burst', fs, T_pause, frequencies, num_cycles)
%
% DESCRIPTION:
% This function creates a signal s(t) of a specified type.
%
% INPUT:
% kind:   kind of signal (see below)
% fs:       sampling rate (in Hz)
% T:        length of the signal (in seconds)
% param:   Some signals require additional information, which can be specified in 'param' (a vector or structure containing the required parameters, depending on the signal kind, see below)
%
% kind can be one of the following:
% 'white':            White noise (no additional parameters required)
% 'pink':             Pink noise (no additional parameters required)
% 'MLS':              Maximum length sequence (MLS). The 'T' parameter is ignored, and param = n is the number of taps to be used for the MLS. The length of the MLS will be 2^n-1 samples.
% 'sine','sin':       Sine wave (param = frequency in Hz)
% 'cosine','cos':     Cosine wave (param = frequency in Hz)
% 'sweep','sweep_log':Sine sweep, where frequency increases exponentially with time (param = [f1 f2], where f1 and f2 are the min. and max frequencies in Hz)
% 'sweep_lin':        Sine sweep, where frequency increases linearly with time (param = [f1 f2], where f1 and f2 are the min. and max frequencies in Hz)
% 'sweep_smooth','sweep_log_smooth': Same as 'sweep' and 'sweep_log', but with a smooth fade-in and fade-out (to reduce high-frequency clicks at beginning and end)
% 'stepsweep','stepsweep_log': Stepped sine sweep; a series of time-shaped sine bursts, whereby the frequency is constant throughout each burst, and increases exponentially from one burst to the next. Bursts are shaped by a Blackman envelope for smooth transition from one burst to the next. The length of each burst is such that all burst contain the same number of sine cycles. param(1): frequency of first burst, param(2): frequency of last burst, param(3): number of bursts, param(4): fractional length of burst envelope with full amplitude [optional, default value: 0.7]. info.f: frequencies of bursts, info.i_end: indices to last sample in each burst, info.Nc: number of cycles in each burst
% 'square':           Square (rectangle) wave (param = frequency in Hz)
% 'rectangle','rect:  Same as 'square'
% 'sawtooth','saw':   Sawtooth wave (param = frequency in Hz)
% 'triangle','tri':   Triangle wave (param = frequency in Hz)
% 'dirac':            Dirac signal (First sample 1, zeroes otherwise)
% 'zero':             Zero signal ('silence')
% 'burst':            Windowed sine bursts spaced 'T_pause' apart. Their frequencies are given by the vector 'frequencies'. Each one is 'num_cycles' sine cycles long and lasts 'num_cycles'/'fs'. 
%                     See 
%                     Shaped Tone-Burst Testing, SIEGFRIED LlNKWITZ,
%                     JOURNAL OF THE AUDIO ENGINEERING SOCIETY, 1980 APRIL, VOLUME 28, NUMBER 4
% 'burstab'           Like 'burst', but alternating between both channels (for A/B tests).
%                     fs = 48e3
%                     vf = mataa_octspace(40, 400, 8)
%                     burst = mataa_signal_generator('burstab', fs, 0.8, vf);
%                     mataa_measure_signal_response(burst,fs,0.3,1,[1 2]);
%
% OUTPUT:
% s: vector containing the signal samples (tha values in s can range from -1...+1)
% t: vector containing the sample times (in seconds)
% info: additional information about the signal (empty in for most signal types; see 'kind' input above).
%
% Examples:
% 1. Create a 1-second pink-noise signal 96kHz sample rate:
% > [pink,t] = mataa_signal_generator('pink',96000,1);
% > plot(t,pink)
%
% 2. Create a 0.1-second 1-kHz square-wave signal with 10 kHz sample rate:
% > [sq,t] = mataa_signal_generator('square',10000,0.1,1000);
% > plot(t,sq)
%
% 3. Create a 1-kHz sine burst windowed by a Hanning window:
% > [burst,t]=mataa_signal_generator('sin',96000,0.01,1000);
% > burst = mataa_signal_window(burst,'hann');
% > plot(t,burst)
%
% 4. Create a series of 20 discrete bursts between 10 Hz and 2 kHz, spaced 300ms apart:
% > [burst, t] = mataa_signal_generator('burst', 48000, 0.3, logspace(log10(10),log10(2000), 20));
% Also see mataa_octspace.
%
%
% FURTHER READING:
% - different kinds of noise: http://en.wikipedia.org/wiki/Colors_of_noise
% - pink noise generation: http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=5091&objectkind=FILE
% - sine sweeps (chirp signals): http://en.wikipedia.org/wiki/Chirp
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
% Copyright (C) 2020 Jens W. Wulf.
% Contact: info@audioroot.net
% Further information: http://www.audioroot.net/MATAA

rand('seed',sum(100*clock)); % 'randomize' rand random generator, in case we need it

dt = 1/fs;

kind = lower(kind);

info = [];

if ~strcmp(kind,'mls')
    N = round(T/dt);
    if N<1
        warning('mataa_signal_generator: duration shorter than sampling interval! Adjusting duration to minimum value.')
        N=1;
    end
    t = [0:N-1]*dt;
end

switch kind
    case 'white'
        s = rand(N,1)*2-1;
        s = s / max(abs(s));
    case 'pink',
        s = M_pinkNoise([N 1],-1);
        s = s / max(abs(s));
    case 'mls',
        n = param;
        if mod(n,1)
            warning('mataa_signal_generator: required length does not match power of 2. Using next power of 2.');
            n = ceil(n);
        end
        s = M_mls(n);
        t = [0:length(s)-1]*dt;
    case {'sine','sin'},
        if param > fs/2
            error('mataa_signal_generator: required signal frequency is higher than fs/2.')
        end;
        s = sin(2*pi*param*t);
    case {'cosine','cos'},
        if param > fs/2
            error('mataa_signal_generator: required signal frequency is higher than fs/2.')
        end;
        s = cos(2*pi*param*t);
    case {'sweep','sweep_log'},
        f1 = param(1); f2=param(2);
        N = round(T/dt);
        t = [0:N-1]*dt;
        k = (f2/f1)^(1/T);
        s = sin(2*pi*f1/log(k)*(k.^t-1));
    case {'sweep_smooth','sweep_log_smooth'},
        [s,t] = mataa_signal_generator ('sweep_log',fs,T,param);
        % fade in and fade out:
        T  = (max(t)-min(t)) / 20;
        i1 = find(t <= T);
        i2 = find(t >= t(end)-T);
        w1 = sin(t(i1)/T/2*pi); w1 = w1(:);
        w2 = flipud(w1);        
        s(i1) = w1 .* s(i1);
        s(i2) = w2 .* s(i2);
    case {'sweep_lin'},
        f1 = param(1); f2=param(2);
        N = round(T/dt);
        t = [0:N-1]*dt;
        k = (f2-f1)/T;
        s = sin(2*pi*(f1+k/2*t).*t);
    case {'stepsweep','stepsweep_log'},
	    f1 = param(1); % frequency of first burst
	    f2 = param(2); % frequency of last burst
		Nb = param(3); % number of bursts
		if length (param) > 3
			bl = param(4); % fractional length of full amplitude burst envelope
		else
			bl = 0.7; % default fractional length of full amplitude burst envelope
		end
		f = logspace (log10(f1),log10(f2),Nb); % frequencies of bursts
		w = 2*pi*f; % omega
		T0 = sum (1./f); % length of signal, if each burst had exactly one cycle (seconds)
		Nc = T/T0; % number of cycles per burst with targeted signal length
		
		if Nc < 1
			error ('mataa_signal_generator: stepsweep: number of cycles in each burst is less than 1. Stopping...')
		end
		
		i_end = round (cumsum(Nc*fs./f)); % indices to last sample of each burst 
		
		s = [];
		for i = 1:Nb % compute bursts
		
			% determine length of burst (seconds):
			if i == 1
				tt = i_end(1) / fs;
			else
				tt = ( i_end(i) - i_end(i-1) ) / fs;
			end
			
			% compute burst:
			b = mataa_signal_generator ('sine',fs,tt,f(i));
			b = mataa_signal_window(b,'blackman',[],bl);
			
			% append:
			s = [ s ; b ];
			
		end
		info.f = f;
		info.i_end = i_end;
		info.Nc = Nc;
    case {'square','rectangle','rect'},
        s = mataa_signal_generator('sin',fs,T,param);
        i = find(s >= 0); j = find(s < 0);
        s(i)=1; s(j)=-1;
    case {'sawtooth','saw'},
        t0 = 1/param;
        s = mod(t,t0)/t0*2-1;
    case {'triangle','tri'},
        s = mataa_signal_generator('saw',fs,T,param);
        i = find(s > 0); s(i)=-s(i);
        s = 2*s+1;
    case {'zero'},
        t = [0:N-1]*dt;
        s = 0*t;
    case {'dirac'},
    	[s,t] = mataa_signal_generator('zero',fs,T);
    	s(1)=1;
    case {'burst'},
      if nargin < 4
        error('Missing arguments.')
      end
      if nargin > 4
        num_cycles = param2;
      else
        num_cycles = 5;
      end
      [s,t] = mataa_signal_generator_burst(fs, param, T, num_cycles);
    case {'burstab'},
      if nargin < 4
        error('Missing arguments.')
      end
      if nargin > 4
        num_cycles = param2;
      else
        num_cycles = 5;
      end
      [s,t] = mataa_signal_generator_burst_ab(fs, param, T, num_cycles);
    otherwise
        error('mataa_signal_generator: unknown signal kind.');
end
% make sure we've got column vectors
t = t(:);
if columns(s) > rows(s)
  s = s';
end
end % of function


function [y, t] = mataa_signal_generator_burst(fs, vf, tPause, num_cycles=5)
  % function [y, t] = mataa_signal_generator_burst(fs, vf, tPause, num_cycles=5)
  %
  %     fs: sampling rate
  %     vf: vector of frequencies
  %     tPause: duration of silence between bursts
  
  
  % Copyright (C) 2020 Jens W. Wulf.
  padding_level = mataa_settings('padding_level');
  y = [];
  t = [];
  toff = 0;
  for n=1:length(vf)
    f = vf(n);
    if n > 1
      toff = t(end) + 1/fs;
      anz = tPause * fs;
      t = [t toff+1/fs*[0:anz-1]];
      y = [y padding_level*ones(1,anz)];
      toff = t(end) + 1/fs;
    end
    % f, fs
    t_ = [0:1/fs:num_cycles/f];
    y_ = sin(2*pi*t_*f) .* (0.5 - 0.5 * cos(2*pi*t_*f/num_cycles));
    t = [t toff+t_]; 
    y = [y y_];
  end
end

function [y, t] = mataa_signal_generator_burst_ab(fs, vf, tPause, num_cycles=5)
  % function [y, t] = mataa_signal_generator_burst(fs, vf, tPause, num_cycles=5)
  %
  %     fs: sampling rate
  %     vf: vector of frequencies
  %     tPause: duration of silence between bursts


  % Copyright (C) 2020 Jens W. Wulf.
  padding_level = mataa_settings('padding_level');
  y = [];
  t = [];
  toff = 0;
  idxf = 1;
  lr   = 0;
  for n=1:2*length(vf)
    f = vf(idxf);
    if n > 1
      toff = t(end) + 1/fs;
      anz = tPause * fs;
      t = [t toff+1/fs*[0:anz-1]];
      y = [y [padding_level*ones(1,anz) ; padding_level*ones(1,anz)] ];
      toff = t(end) + 1/fs;
    end
    % f, fs
    t_ = [0:1/fs:num_cycles/f];
    y_ = sin(2*pi*t_*f) .* (0.5 - 0.5 * cos(2*pi*t_*f/num_cycles));    
    t = [t toff+t_];
    % Silence other channel:
    ys_ = padding_level*ones(1,length(y_));
    %
    if lr == 0
      y = [y [y_ ; ys_] ];
      lr = 1;
    else
      y = [y [ys_ ; y_] ];
      lr = 0;
      idxf += 1;
    end
  end
end


%%%%%%   
%%%%%%   pink = M_pinkNoise([N 1],-1);
%%%%%%   
%%%%%%
function x = M_pinkNoise(DIM,BETA)
% function x = M_pinkNoise(DIM, BETA)
%
% This function generates 1/f spatial noise, with a normal error 
% distribution (the grid must be at least 10x10 for the errors to be normal). 
% 1/f noise is scale invariant, there is no spatial scale for which the 
% variance plateaus out, so the process is non-stationary.
%
%     DIM is a two component vector that sets the size of the spatial pattern
%           (DIM=[10,5] is a 10x5 spatial grid)
%     BETA defines the spectral distribution. 
%          Spectral density S(f) = N f^BETA
%          (f is the frequency, N is normalisation coeff).
%               BETA = 0 is random white noise.  
%               BETA  -1 is pink noise
%               BETA = -2 is Brownian noise
%          The fractal dimension is related to BETA by, D = (6+BETA)/2
% 
% Note that the spatial pattern is periodic.  If this is not wanted the
% grid size should be doubled and only the first quadrant used.
%
% Time series can be generated by setting one component of DIM to 1

% The method is briefly descirbed in Lennon, J.L. "Red-shifts and red
% herrings in geographical ecology", Ecography, Vol. 23, p101-113 (2000)
%
% Many natural systems look very similar to 1/f processes, so generating
% 1/f noise is a useful null model for natural systems.
%
% The errors are normally distributed because of the central
% limit theorem.  The phases of each frequency component are randomly
% assigned with a uniform distribution from 0 to 2*pi. By summing up the
% frequency components the error distribution approaches a normal
% distribution.

% Written by Jon Yearsley  1 May 2004
%     j.yearsley@macaulay.ac.uk
%
% S_f corrected to be S_f = (u.^2 + v.^2).^(BETA/2);  2/10/05


% Generate the grid of frequencies. u is the set of frequencies along the
% first dimension
% First quadrant are positive frequencies.  Zero frequency is at u(1,1).
u = [(0:floor(DIM(1)/2)) -(ceil(DIM(1)/2)-1:-1:1)]'/DIM(1);
% Reproduce these frequencies along ever row
u = repmat(u,1,DIM(2));
% v is the set of frequencies along the second dimension.  For a square
% region it will be the transpose of u
v = [(0:floor(DIM(2)/2)) -(ceil(DIM(2)/2)-1:-1:1)]/DIM(2);
% Reproduce these frequencies along ever column
v = repmat(v,DIM(1),1);

% Generate the power spectrum
S_f = (u.^2 + v.^2).^(BETA/2);

% Set any infinities to zero
S_f(S_f==inf) = 0;

% Generate a grid of random phase shifts
phi = rand(DIM);

% Inverse Fourier transform to obtain the the spatial pattern
x = ifft2(S_f.^0.5 .* (cos(2*pi*phi)+i*sin(2*pi*phi)));

% Pick just the real component
x = real(x);
end % of function



% FROM http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=1246&objectkind=file
function  y = M_mls(n,flag)

%y = mls(n,{flag});
%
%Generates a Maximum Length Sequence of n bits by utilizing a 
%linear feedback shift register with an XOR gate on the tap bits 
%
%Function can accept bit lengths of between 2 and 24
%
%y is a vector of 1's & -1's that is (2^n)-1 in length.
%
%optional flag is:
%
%  1 for an initial sequence of all ones (repeatable)
%  0 for an initial sequence that is random (default)
%
%note: Because of the recursive nature of this process, it is not 
%possible to completely vectorize this code (at least I don't know 
%how to do it). As a result, longer bit lengths will take quite a 
%long time to process, perhaps hours. If you figure out a way to 
%vectorize the for loop, please let me know.
%
%reference:
%	Davies, W.D.T. (June, July, August, 1966). Generation and 
%properties of maximum-length sequences. Control, 302-4, 364-5,431-3.
%
%Spring 2001, Christopher Brown, cbrown@phi.luc.edu

switch n								%assign taps which will yeild a maximum
case 2								%length sequence for a given bit length
   taps=2;							%I forget the reference I used, but theres
   tap1=1;							%a list of appropriate tap values in
   tap2=2;							%Vanderkooy, JAES, 42(4), 1994.
case 3
   taps=2;
   tap1=1;
   tap2=3;
case 4
   taps=2;
   tap1=1;
   tap2=4;
case 5
   taps=2;
   tap1=2;
   tap2=5;
case 6
   taps=2;
   tap1=1;
   tap2=6;
case 7
   taps=2;
   tap1=1;
   tap2=7;
case 8
   taps=4;
   tap1=2;
   tap2=3;
   tap3=4;
   tap4=8;
case 9
   taps=2;
   tap1=4;
   tap2=9;
case 10
   taps=2;
   tap1=3;
   tap2=10;
case 11
   taps=2;
   tap1=2;
   tap2=11;
case 12
   taps=4;
   tap1=1;
   tap2=4;
   tap3=6;
   tap4=12;
case 13
   taps=4;
   tap1=1;
   tap2=3;
   tap3=4;
   tap4=13;
case 14
   taps=4;
   tap1=1;
   tap2=3;
   tap3=5;
   tap4=14;
case 15
   taps=2;
   tap1=1;
   tap2=15;
case 16
   taps=4;
   tap1=2;
   tap2=3;
   tap3=5;
   tap4=16;
case 17
   taps=2;
   tap1=3;
   tap2=17;
case 18
   taps=2;
   tap1=7;
   tap2=18;
case 19
   taps=4;
   tap1=1;
   tap2=2;
   tap3=5;
   tap4=19;
case 20
   taps=2;
   tap1=3;
   tap2=20;
case 21
   taps=2;
   tap1=2;
   tap2=21;
case 22
   taps=2;
   tap1=1;
   tap2=22;
case 23
   taps=2;
   tap1=5;
   tap2=23;
case 24
   taps=4;
   tap1=1;
   tap2=3;
   tap3=4;
   tap4=24;
%case 25
%   taps=2;
%   tap1=3;
%   tap2=25;
%case 26
%   taps=4;
%   tap1=1;
%   tap2=7;
%   tap3=8;
%   tap4=26;
%case 27
%   taps=4;
%   tap1=1;
%   tap2=7;
%   tap3=8;
%   tap4=27;
%case 28
%   taps=2;
%   tap1=3;
%   tap2=28;
%case 29
%   taps=2;
%   tap1=2;
%   tap2=29;
%case 30
%   taps=4;
%   tap1=1;
%   tap2=15;
%   tap3=16;
%   tap4=30;
%case 31
%   taps=2;
%   tap1=3;
%   tap2=31;
%case 32
%   taps=4;
%   tap1=1;
%   tap2=27;
%   tap3=28;
%   tap4=32;
otherwise
   disp(' ');
   disp('input bits must be between 2 and 24');
   return
end

if (nargin == 1) 
	flag = 0;
end

if flag == 1
	abuff = ones(1,n);
else
    if exist('OCTAVE_VERSION','builtin')
        rand('seed',sum(100*clock));
    else
	   rand('state',sum(100*clock));
	end
	
	while 1
		abuff = round(rand(1,n));
		%make sure not all bits are zero
		if find(abuff==1)
			break
		end
	end
end

for i = (2^n)-1:-1:1
      
   xorbit = xor(abuff(tap1),abuff(tap2));		%feedback bit
   
   if taps==4
      xorbit2 = xor(abuff(tap3),abuff(tap4));%4 taps = 3 xor gates & 2 levels of logic
      xorbit = xor(xorbit,xorbit2);				%second logic level
   end
   
	abuff = [xorbit abuff(1:n-1)];
	y(i) = (-2 .* xorbit) + 1;  	%yields one's and negative one's (0 -> 1; 1 -> -1)
end
end % of function


