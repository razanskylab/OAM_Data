% [out] = Correct_Shot_Jitter(SDO,In) @ SDO
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Correct_Shot_Jitter(SDO)
  SDO.Verbose_Warn('[SDO] Correct_Shot_Jitter not yet implemtented!\n');
  % FIXME this is only to correct jitter based on known, per shot shift values
  % finding jitter is done in seperate function
  % (and really only works for PD data I assume...)

  %
  % % jitter correction
  % Conf.NoJitter.use = 1; % use jitter removal?
  % Conf.NoJitter.cropPdSignals = true; % crop pd signals prior to processing for speed up
  % Conf.NoJitter.interpFactor = 4; % 4 is better for transition method, 2 is ok for other
  % Conf.NoJitter.detectionMethod = 0;
  % % 0 - vec. transition, 1 - vect. xCorr, 2 - vect. max, 3 - parfor xCorr

  % find jitter from pd signals
  % [usShots] = remove_shot_jitter(usShots,ExpData,Conf);

  % Find Shot Jitter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % TODO [jitter] = dp_get_signal_shifts(pdShots,Conf)
  % [ExpData] = get_signal_shifts(ExpData,Conf);

  % Remove Shot Jitter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % dp_remove_shot_jitter
end
