% RemoveWiggle class,
% for performance purposes, RemoveWiggle Class does not have data
% properties but all methods take position data etc. as input
% this avoids copying of data when not needed....
% FIXME add pos and velocity info together with other usefull parameters???
% overhaul very crude wiggle remove class, add more sensible options
% also have usefull

% FIXME the following old settings and related functions should probably
% be converted into a wiggle removal class with appr. settings etc...

% new options for delay removal
% doFixDelay(1,1)    {mustBeNumeric, mustBeFinite} = 0; % delay removal experimental, don't do it by default right now
% assumedShift(1,1)  {mustBeNumeric, mustBeFinite} = 650e-6; % empirically found shift
% extraShift(1,1)    {mustBeNumeric, mustBeFinite} = 0; % play with extra shift for better performance


classdef RemoveWiggle < BaseClass
  properties
    method(1,1)        {mustBeNumeric, mustBeFinite} = 0;
      % 0 = smooth position data, the get vel from gradient
      % also uses the smooth position data for later interpolation
      % 1 = get vel from position gradient, smooth vel, don't smooth pos data
    limitSpeed(1,1)    {mustBeNumeric, mustBeFinite} = 0.05;  %remove shots where velocity is too small for new one way
    direction(1,1)     {mustBeNumeric, mustBeFinite} = 0; % 1 = forward (x-vel > 0), 0 = backward (x-vel < 0)
    meanFiltWidth(1,1) {mustBeNumeric, mustBeFinite} = 100;  % only used when method = 0, width of filter in ms
    medFiltWidth(1,1)  {mustBeNumeric, mustBeFinite} = 10;  % only used when method = 1, width of filter in ns
  end

  methods
    function [onewayIdx] = Get_One_Way_Index(RW,xPos,dt)
      % [onewayIdx] = Get_One_Way_Index(RW,xPos,dt)
      % takes the measured x-position data, calculates the velocity of the x-stage
      % and filters it using a median filter to get rid of the velocity spikes
      % then, the indicies of the shots for stage movement in the pos. and neg.
      % directions are extracted using a treshold velocity (RW.limitSpeed)
      RW.VPrintF('   Finding pos. & neg. direction shots based on velocity.\n');

      tVec = (0:(numel(xPos)-1))*dt;
      switch RW.method
      case 0 % the new way, with position smoothing using moving mean via convolution
        % RW.meanFiltWidth = 21; % meanFiltWidth in ns
        filterWidth = floor((RW.meanFiltWidth*1e-3)/dt);
        filterShape = ones(1,filterWidth)./filterWidth; % moving average filter
        startVal = mean(xPos(1:filterWidth));
        endVal = mean(xPos((end-filterWidth):end));
        xPos = conv(xPos,filterShape,'same');
        % get rid of edge effects of the convolution
        xPos(1:filterWidth) = startVal;
        xPos((end-filterWidth):end) = endVal;
        % cal velocity from smoothed postion
        xVelocity = gradient(xPos,tVec);
        % filter velocity profile as well to make it just a little smoother
        xVelocity = medfilt1(xVelocity,floor(filterWidth./5));

      case 1 % the old way, with velocity smoothing using medfilt
        % use median filter to smooth out velocity data to have more robust
        xVelocity = gradient(xPos,tVec);
        filterWidth = floor((RW.medFiltWidth*1e-3)/dt);
        xVelocity = medfilt1(xVelocity,medianFiltOder);
      end


      xVelocity(1:filterWidth) = 0; % get's rid of velocity spike at beginning if not starting from x=0
      % direction detection based on velocity
      xVelocity = xVelocity/(max(abs(xVelocity(:)))); %normalize speed for more robustness
      if RW.direction
        onewayIdx = xVelocity > RW.limitSpeed;
      else
        onewayIdx = xVelocity < -RW.limitSpeed;
      end

      if false();
        C = Colors();
        figure();
        onewayIdxPlot = (single(onewayIdx))*2;
        area(tVec(1:2000),onewayIdxPlot(1:2000),'FaceAlpha',0.25,'FaceColor',C.DarkGreen);
        hold on;
        plotPos = ((xPos./max(xPos(:))))*2;
        plot(tVec(1:2000),xVelocity(1:2000));
        plot(tVec(1:2000),plotPos(1:2000));
        axis tight;
        legend('Keep?','Velocity','pos');
        title('Find one way Index');
        print_info_stamp_in_figure();
      end
    end % end get_oneway_index fct
  end % end methods

end
