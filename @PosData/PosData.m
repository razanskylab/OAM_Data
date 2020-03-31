% PosData Description goes here!

classdef PosData < BaseClass

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties
    % settings -----------------------------------------------------------------
    useSampledRoi(1,1) {mustBeNumericOrLogical} = false;
      % when true, will output roi and x,y based on sampled x-positions
      % when false, will output based on targeted values from scan settings
      % this can cause a shift between sampled area and output image and cause
      % parts of the recon to have no information
      % NOTE this should not even happen and needs to be fixed in the stage
      % calibration code ASAP!
    oneWayDirection(1,1) {mustBeNumeric,mustBeInteger} = 1;
      % direction to keep when removing wiggle
      % 1/0 - keep part where v>0
      % -1  - keep part where v<0
      % see Get_One_Way_Index()
    oneWaySpeed(1,1) {mustBeNumeric,mustBeFinite} = 0.05;
      % normalized limit speed, below this stage is assumed to be staionary
    overSampling(1,2) {mustBeNumeric,mustBeFinite} = [1 1];
      % modifier for x-y sampling, stepsize will be divided by this (nSteps
      % multiplied) to get oversampling for >1 and undersampling for < 1
  end

  properties
    % data defining size etc of the final output image -------------------------
    ctr(1,2) {mustBeNumeric} = [0 0]; % [mm] xCtr yCtr, in real, absolute coordinates
    width(1,2) {mustBeNumeric} = [0 0]; % [mm] [xWidth yWidth] width of roi
    dr(1,2) {mustBeNumeric} = 0 % [mm] x/y steps size of scan
    prf(1,:) {mustBeNumeric} = 0; % [Hz], shot frequency,
      % for pos-based trigger this is no longer a scalar value
    bScanRate(1,1) {mustBeNumeric} = 0; % n Bscans per second
    nBscans(1,1) {mustBeNumeric} = 0;% number of bscans we should have
    moveTime(1,1) {mustBeNumeric} = 0;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties
    % these props. have the same time/sample space as the us and oa data
    % so when a shot is removed from the raw data for one of the various reasons
    % these vectors also have to be changed, they can't be re-calculated!!!
    % xS is a normal set property, all other are calculated based ot xS etc...
    xS(1,:) {mustBeNumeric}; % sampled / calculated x-pos for each shot
    xVel(1,:) {mustBeNumeric}; % calculated x-velocity for each shot

    yS(1,:) {mustBeNumeric}; % calculated y-pos for each shot
    yVel(1,:) {mustBeNumeric}; % calculated y-velocity for each shot

    tS(1,:) {mustBeNumeric}; % [s] time at which yS and xS are sampled
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % depended properties are calculated from other properties
  properties (Dependent = true)
    roi; % planned or sampled, see useSampledRoi setting
    targetRoi; % roi as planned, not as sampled
    drS; % (dr./overSampling), i.e. step size used for the actual data acq.
    nSteps; % number of steps in x and y
    nStepsS; % nSteps based on sampled step size (drS), i.e. when modfied by oversampling

    nShots;

    dt; % 1/prf
    % t; % [s] time vector of size xS/yS, used for plotting and speed calc?
    bScanPeriod;
    scanTime; % theoretical scan time based on bScanPeriod and nXSBscans

    % these are regular, absolute x,y vectors, based on ROI, with length = nSteps
    % calculate based on ROI, dr and nSteps!
    x;
    y;

    % these are regular, absolute x,y vectors, but in parametric form,
    % i.e. each xReg(1)|yReg(1)... xReg(n)|yReg(n) with n = nShots defines
    % a point in a regularly spaced x-y grid, mostly used for remapping and plotting
    xReg;
    yReg;

    % these are regular, relative x,y vectors, based on x,y centered at zero
    xRel;
    yRel;

    % vectors storing actual postion, as measured by laser and calculate for owis
    % but centered at zero
    xSRel;
    ySRel;

    smoothWidth; % nSamples to smooth over without changing min/max of pos data
    yVelTarget; % [mm/s] vel y-stage should have had theoreticaly for given scanTime and width
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties
    % these are really dependend properties but are expensive to calcualte
    % so we caluclate them in specific functions instead of set/get functions

    maxVel(1,2) {mustBeNumeric} = [0 0]; % max vel reached by x-stage
    maxDr(1,2) {mustBeNumeric} = [0 0]; % actual max step size based on max vel
    nXSBscans(1,1) {mustBeNumeric} = 0; % actual number of b-scans, as measured by zero crossings?

    % remapping related...NOTE see Calculate_Triangulation()
    DelaunayTri; % delaunayTriangulation object
    nearIdx(1,:) {mustBeNumeric}; % idx of  nearest neighbor, maps xS|yS to xReg|yReg
    closeness(1,:) {mustBeNumeric} = 0; % idx of  nearest neighbor, maps xS|yS to xReg|yReg
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % constant properties --------------------------------------------------------
  properties (Constant)
    % used in detection of start / end idx
    N_OSC_PERIODS = 40; % 5 is a bit close in some cases
    SPEED_LIM_PER = 5; % [%] percent of max speed that is considered movement for the x-stage
    VERBOSE_PLOT_DEFAULT = false; % set in based class, overwritten in constructor
    ALLOWED_RATE_DIFF = 0.5; % [Hz] see Find_B_Scan_Rate()
    SMOOTH_FRACTION = 1/25; % part of a bScanPeriod to smooth over, see smoothWidth

    Y_ACC = 40; % specific to OWIS but constant, checked on 09/11/2018 via Owis software
  end

  properties
    % defined in base class but this way we can have set/get in sublcasses, which
    % is % needed for FOAM processor
    silent(1,1) {mustBeNumericOrLogical} = false;
    verboseOutput(1,1) {mustBeNumericOrLogical} = true; % more detailed output to workspace...
    verbosePlotting(1,1) {mustBeNumericOrLogical} = false; % more figures...
    figureVisibility(1,:) char {mustBeMember(figureVisibility,{'on','off'})} = 'on';
  end

  % same as constant but now showing up as property
  properties (Constant,Hidden=true)
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % constructor, desctructor, save obj
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % constructor, called when class is created
    function Pos = PosData()
      Pos.verbosePlotting = Pos.VERBOSE_PLOT_DEFAULT;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor: Mainly used to close the serial connection correctly
    function delete(POS)
      % close connections etc
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % when saved, hand over only properties stored in saveObj
    function SaveObj = saveobj(POS)
      % only save public properties of the class if you save it to mat file
      % without this saveobj function you will create an error when trying
      % to save this class
      SaveObj = POS;
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access = private)
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods % SET / GET methods
  %%===========================================================================
    function roi = get.roi(Pos)
      % if Pos.useSampledRoi
      %   if ~any(Pos.xSRoi) % sampled x-roi still needs to be calculated
      %     if isempty(Pos.xSSmooth)
      %       Pos.xSSmooth = movmean(Pos.xS,Pos.smoothWidth);
      %     end
      %     minX = min(Pos.xSSmooth);
      %     maxX = max(Pos.xSSmooth);
      %     Pos.xSRoi = [minX maxX];
      %   end
      %   if ~any(Pos.ySRoi) && any(Pos.yS) % sampled x-roi still needs to be calculated
      %     minY = min(Pos.yS);
      %     maxY = max(Pos.yS);
      %     Pos.ySRoi = [minY maxY];
      %     roi = [Pos.xSRoi(1) Pos.xSRoi(2) Pos.ySRoi(1) Pos.ySRoi(2)];
      %   elseif ~any(Pos.ySRoi) && ~any(Pos.yS)
      %     roi = [Pos.xSRoi(1) Pos.xSRoi(2) Pos.targetRoi(3) Pos.targetRoi(4)];
      %   else
      %     roi = [Pos.xSRoi(1) Pos.xSRoi(2) Pos.ySRoi(1) Pos.ySRoi(2)];
      %   end
      % else
        roi = Pos.targetRoi;
      % end
    end

    function targetRoi = get.targetRoi(Pos)
      targetRoi = [Pos.ctr(1) - Pos.width(1)/2, ...
            Pos.ctr(1) + Pos.width(1)/2, ...
            Pos.ctr(2) - Pos.width(2)/2, ...
            Pos.ctr(2) + Pos.width(2)/2];
    end
    %%===========================================================================
    function nSteps = get.nSteps(Pos)
      nSteps = round(Pos.width./Pos.dr);
      nSteps(1) = nSteps(1) + 1;
    end
    %%===========================================================================
    function nStepsS = get.nStepsS(Pos)
      % number of steps modified by oversampling, i.e. the ones used during
      % actual scan
      nStepsS = ceil(Pos.width./Pos.drS);
    end

    %%===========================================================================
    function drS = get.drS(Pos)
      drS = Pos.dr./Pos.overSampling;
    end


    %%===========================================================================
    function nShots = get.nShots(Pos)
      if ~isempty(Pos.xS) %  length(x) same as ~isempty(x)
        nShots = length(Pos.xS);
      else
        nShots = 0;
      end
    end
    function dt = get.dt(Pos)
      dt = 1./Pos.prf;
    end

    %%===========================================================================
    % time it takes x-stage to travel back and forth once / 2
    function bScanPeriod = get.bScanPeriod(Pos)
      bScanPeriod = 1./Pos.bScanRate; % [s]
    end
    function scanTime = get.scanTime(Pos) % [s]
      scanTime = Pos.bScanPeriod * Pos.nXSBscans;
    end

    %%===========================================================================
    function x = get.x(Pos)
      % x = Pos.roi(1):Pos.dr:Pos.roi(2); % this is the easy way, but we can
      % miss the end point if we have an off step size
      x = linspace(Pos.roi(1),Pos.roi(2),Pos.nSteps(1));
      x = double(x); % double is most compatible
    end
    function y = get.y(Pos)
      y = linspace(Pos.roi(3),Pos.roi(4),Pos.nSteps(2));
      y = double(y); % double is most compatible
    end

    %%===========================================================================
    function xReg = get.xReg(Pos)
      % xReg = Pos.roi(1):Pos.dr:Pos.roi(2); % this is the easy way, but we can
      % miss the end point if we have an off step size
      xReg = repmat(Pos.x,1,Pos.nSteps(2));
      % xReg = repmat([Pos.x fliplr(Pos.x)],1,floor(Pos.nSteps(2)/2));
      % if mod(Pos.nSteps(2),2)
      %   %uneven number of samples along y, add XPosVec vector in xReg after remap
      %   xReg = [xReg idealXPosVec];
      % end
    end
    function yReg = get.yReg(Pos)
      yReg = repelem(Pos.y,Pos.nSteps(1)+1); % staircase
    end

    %%===========================================================================
    function xRel = get.xRel(Pos)
      xRel = Pos.x - mean(Pos.x); % center around zero
    end
    function yRel = get.yRel(Pos)
      yRel = Pos.y - mean(Pos.y); % center around zero
    end

    %%===========================================================================
    function xSRel = get.xSRel(Pos)
      % FIXME get center using fit instead of measured data!
      xSctr = mean([max(Pos.xS) min(Pos.xS)]); % more accurate than mean in most cases...
      xSRel = Pos.xS - xSctr; % center around zero
    end
    function ySRel = get.ySRel(Pos)
      % FIXME get center using fit instead of measured data!
      ySctr = mean([max(Pos.yPos) min(Pos.yPos)]); % more accurate than mean in most cases...
      ySRel = Pos.yPos - ySctr; % center around zero
    end
    %%===========================================================================
    function smoothWidth = get.smoothWidth(Pos)
      % get nSamples to smooth over based on prf and bscan period
      % smoot position data using moving mean and with window size small
      % enough to not perturb the oscilations
      smoothWidth = round(Pos.bScanPeriod*Pos.SMOOTH_FRACTION*Pos.prf); % i.e. quarter of half a period...
    end

    %%===========================================================================
    function yVelTarget = get.yVelTarget(Pos)
      yAcc = Pos.Y_ACC*1e-3;
      yWidth = Pos.width(2)*1e-3; % [mm/s -> m/s]
      yVelTarget = get_vel_for_fixed_acc(yAcc,yWidth,Pos.scanTime)*1e3; % get velocity profile
    end

  end

end
