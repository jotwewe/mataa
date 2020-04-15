function ir = raa_sum_IR_nearfield(varargin)
  % function ir = raa_sum_IR_nearfield(IR_1, S_1, IR_2, S_2, ..)
  % 
  %     Sum impulse responses acquired by near field measurements.
  %
  %
  %     The function expects an even number of arguments in pairs of 
  %     impulse response (a struct with fields 'h' -- impulse response
  %     and 'fs' -- sampling rate) and effective area of port or driver.
  %     The unit of all those areas has to be the same, but does not
  %     matter otherwise.
  %
  %     Method and weighting:
  %      - Low-Frequency Loudspeaker Assessment by Nearfield Sound-Pressure Measurement
  %        D. B. KEELE, JR
  %        JOURNAL OF THE AUDIO ENGINEERING SOCIETY, APRIL 1974, VOLUME 22, NUMBER 3
  %        -> proportional to radius
  %      - Simulated Free Field Measurements
  %        CHRISTOPHER J. STRUCK, STEVE F. TEMME
  %        J. AudioEng. Soc., Vol. 42, No.6, 1994 June
  %        -> explicitly notes: sum of all port areas should be used
  %      - Measuring Loudspeaker Low-Frequency Response
  %        Joe D'Appolito
  %        audioxpress 2018
  %        https://audioxpress.com/article/measuring-loudspeaker-low-frequency-response
  %        -> weight every port/piston with its diameter or square root of its area
  %      - Measuring Loudspeaker Low-Frequency Response
  %        Joe D'Appolito
  %        http://www.audiomatica.com/wp/wp-content/uploads/Testing-Loudspeakers-at-low-Frequencies-with-CLIO.pdf
  %        This partly differs from the audioxpress article above.
  %        -> weight every port/piston with its diameter or square root of its area
  %      - AN 38, Near Field Measurement of Systems with Multiple Drivers and Ports
  %        Application Note to the KLIPPEL R&D SYSTEM
  %        Klippel GmbH     
  %        -> weight every port/piston with square root of its area
  %
  %     For a vented box with two identical ports, what's the right way to do it?
  %     Obviously 2*sqrt(1) > sqrt(2), so
  %     raa_sum_IR_nearfield(ir_driver, S_driver, ir_port, S_port, ir_port, S_port) > raa_sum_IR_nearfield(ir_driver, S_driver, ir_port, 2*S_port)
  %     
  %     The smaller result matches a microphone-in-box-measurement the author
  %     made and is according to Struck/Temme above, but different from the others.
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.

  if bitand(nargin, 1) ~= 0
    error('Expecting an even number of arguments.')
  end
  num = nargin / 2;
  
  ir.fs = varargin{1}.fs;
  ir.h  = 0;
  ir    = raa_propagate_meta(ir, varargin{1});    
    
  % Aref  = sum(cell2mat({varargin{[0:num-1]*2+2}}));
  Aref  = varargin{2};
  
  for n=0:num-1
    ir.h += varargin{n*2+1}.h * sqrt(varargin{n*2+2} / Aref);
    if ir.fs ~= varargin{n*2+1}.fs
      error("Can't handle different sampling rates");
    end
    if n > 0
      ir.name = [ir.name ' + ' varargin{n*2+1}.name];
    end
  end
end
