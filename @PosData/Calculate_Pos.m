% [yPos] = Calculate_Y_Pos(Pos) @ Pos
% calculate y-pos based on speed and duration of scan, also calculate smoothed
% y-pos and velocity profiles (ySSmooth and yVel)
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018
% based on code by Hector Estrada

function [yPos,yVel] = Calculate_Pos(Pos)
  tic;
  Pos.VPrintF('Calculating xy-stage trajectory...');
  % ----------------------------------------------------------------------------
  % calculate y-trajectory
  % FIXME read values from stage...but we didn't save them yet...
  % calculate y-stage speed for a given, maximum acceleration
  a = 50*1e-3; % m/s²
  dy = Pos.width(2)*1e-3; % m
  t = Pos.moveTime;
  v = a*t/2 - sqrt(a.^2*t.^2/4 - a*dy); % urs did this...just believe!!!

  % convert to correct units again
  v = v*1e3; % [mm/s] y-stage max speed
  a = a*1e3; % [mm²/s] acceleration
  %
  accTime = v./a; % [s]
  Pos.tS = Pos.tS - min(Pos.tS); % pos ts == 0 probably at DAQ.Start

  accIdx = find(Pos.tS>accTime,1);
  decIdx = numel(Pos.tS) - accIdx + 1;
  accTimes = Pos.tS(1:accIdx);
  constTime = Pos.tS(accIdx+1:decIdx-1);
  decTime = Pos.tS(decIdx:end);

  sStart = a*accTimes.^2/2;
  sConst = -1/2*v.^2./a + v*constTime;
  sStop = -fliplr(sStart) + max(sStart);

  % make sStop allign with end of const movement
  dS = sConst(1)-sStart(end);
  sStop = sStop + sConst(end) + dS;

  if 0
    figure()
    plot(accTimes,sStart);
    hold on
    plot(constTime,sConst);
    plot(decTime,sStop);
  end
  Pos.yS = [sStart sConst sStop];
  Pos.yS = Pos.y(1) + Pos.yS; % start at correct start position
  % Pos.yVel = gradient(Pos.yS,Pos.tS);

  upMove = Pos.x;
  downMove = fliplr(upMove);
  fullMove = [upMove downMove];
  Pos.xS = repmat(fullMove,1,Pos.nSteps(2)./2);
  % Pos.xVel = gradient(Pos.xS,Pos.tS);


  Pos.Done();
end
