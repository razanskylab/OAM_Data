% [out] = Get_One_Way_Index(Pos,In) @ Pos
% takes the measured x-position data, calculates the velocity of the x-stage
% and filters it using a median filter to get rid of the velocity spikes
% then, the indicies of the shots for stage movement in the pos. and neg.
% directions are extracted using a treshold velocity (Pos.oneWaySpeed)
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [oneWayIdx] = Find_One_Way_Index(Pos)

  t1 = tic;
  Pos.VPrintF('   Finding one-way shots based on velocity...');

  tVec = Pos.tS;
  xVelocity = medfilt1(Pos.xVel,floor(Pos.smoothWidth));
  xVelocity = xVelocity/(max(abs(xVelocity(:)))); %normalize speed for more robustness
  if Pos.oneWayDirection >= 0
    oneWayIdx = xVelocity > Pos.oneWaySpeed;
  else
    oneWayIdx = xVelocity < -Pos.oneWaySpeed;
  end
  Pos.Done(t1);

  if Pos.verbosePlotting;
    C = Colors();
    figure();
    onewayIdxPlot = (single(oneWayIdx))*2;
    area(tVec(1:2000),onewayIdxPlot(1:2000),'FaceAlpha',0.25,'FaceColor',C.DarkGreen);
    hold on;
    plotPos = Pos.xS - mean(Pos.xS(:));
    plotPos = ((plotPos./max(plotPos(:))))+1;
    plot(tVec(1:2000),xVelocity(1:2000)+1);
    plot(tVec(1:2000),plotPos(1:2000));
    axis tight;
    legend('Keep?','Velocity','pos');
    title('Find one way Index');
    print_info_stamp_in_figure();
  end
end
