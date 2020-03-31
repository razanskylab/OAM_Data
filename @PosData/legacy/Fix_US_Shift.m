% Fix_US_Shift(Pos,sampleShift) @ Pos
% resamples RAW position vector in an attempt to fix the US shift bug
% we have for some datasets...lets hope and pray
% shift pos vector slightly via resampling
% at beginning and then it hopefully accumulates linearly...
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018


function [] = Fix_US_Shift(Pos,sampleShift)
  tic;
  Pos.VPrintF('   Fixing US shitty shifty bug:\n');
  Pos.VPrintF('   Resampling raw position data by %i samples...',sampleShift);
  origLength = length(Pos.xS);
    % keep this and return vector to this length at the end

  p = Pos.nShots;
  q = Pos.nShots-sampleShift;
  [pp,qq] = rat( p/q, 1e-6);
  if pp*qq > 2^31 % will result in error...
    [pp,qq] = rat(p/q, 5e-5);
  end
    % approximate resample based on fraction of nShots vs. shots we would have wanted
  absolutePos = mean(Pos.xS);
  Pos.xS = Pos.xS - absolutePos; % make position zero centered
  Pos.xS = single(resample(double(Pos.xS),pp,qq));
  Pos.xS = Pos.xS + absolutePos; % shift back to keep absolute positions

  Pos.tS = (0:Pos.nShots-1)*Pos.dt; % based on laser PRF
  Pos.xSSmooth = movmean(Pos.xS,Pos.smoothWidth);
  Pos.xVel = gradient(Pos.xSSmooth,Pos.dt);

  % crop/extend xS back to orig length
  if origLength > length(Pos.xS) % signal to short now, pad it with last entry
    lengthDiff = origLength - length(Pos.xS);
    Pos.xS(end+1:end+lengthDiff) = Pos.xS(end);
  elseif origLength < length(Pos.xS) % pos signal too long now, crop it
    Pos.xS = Pos.xS(1:origLength);
  end

  % see jr_18_12_29_hunting_us_shift_bug for how it works...
  Pos.Done();

end
