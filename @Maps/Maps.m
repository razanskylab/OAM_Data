%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optoacoustic Image Processing Toolbox
% this is optimized for convenience, not for performance! Do not use this class
% on a large number of images...
% JR - 2017 - IBMI
% the general idea of this class is to consequtively apply filters and processing
% to a 2d image, where the image is stored in the maps class and typically
% processed by other sub-classes where the images are stored as M."ClassName".filt
% whenever a filter class is applied, an even is triggered that updates the Map.filt
% property...
% if you want to use that filtered image for further processing, you need to update
% M.xy with the filtered result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Maps < BaseClass
  properties (Constant = true)
    % Get colors and colors maps
  end

  properties
    C = Colors();
    Path = Path; % see Paths class definition

    xy;% maps to be stored and plotted / calculated
    x; y;% plot vectors with units (mm)
    xMidplane; yMidplane; % used to split Map along this plane/idx, splits x and y accordingly
    % maps to be combined, i.e. sigMap and depthMap
    % signal; % signal map used for overlay

    raw; % original xy map, as first input to Maps structure
    filt; % store frangi filtered images seperate
    filtScales; % store seperate frangi scales
    bin; % binarize/segmented xy map
    area; % area of maps in units of x/y, so should be mm²

    %% depth processing and plotting related
    % depth; % overlayed depth map, i.e. depthinfo overlayed on signal map
    depthInfo; % legacy for now
    rawDepth; % depth map with depth info for all pixels, raw from 3d signal
    filtDepth; % processed depth map to be overlayed over xy map, signal etc

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create instances of image processing, filtering and analysis classes
    % see respective class folders for details
    Frangi = Frangi_Filter(); % create instance of Frangi class, see @Frangi for details
    ImFilter = Image_Filter();
    AVA = Vessel_Analysis();

    % Binarization Options  -------------------------------------------------------
    binWhat = 0; % Which image should I use as basis for binarization?
    %                 0 - Frangi filtered image
    %                 1 - based on M.xy
    %                 2 - signal map
    % when using frangi to binarize image, use these Frangi settings
    binFrangiStart = 1;
    binFrangiStop = 6;
    binFrangiNoScales = 10;
    binFinalThreshold = 0.3;
    % multiply frangi image by xy prior to binarization, makes binarization less aggressive
    % changing binFinalThreshold is better way to take care of this though...
    binMultiplyMap = false;

    pixelDensity = 100*1000; % default pixel density [pixel / m]

    % Vessel statisitics Options
    VesselStats = struct([]); % stats calculates using Get_Vessel_Stats()
    VesselData = struct([]); % stats calculates using Get_Vessel_Stats()

    % settings for general functions (interp, padding, etc)
    interpMethod = 'linear';
    interpFactor = 2;

    % overlay transparent mask option, used in Overlay_Mask
    maskFrontCMap = Colors.whiteToRed;
    maskBackCMap = 'gray';
    maskAlpha = 1; %[0-1], 0 = fully transp. , 1 = full opaque

    % plotting options ---------------------------------------------------------
    showHisto = 0; % default don't show histo for xy-plots
    useUnits = true; % plot using units not index if possbile
    prettyColorMap = hot(2^8); % used for combined sigmat plots
    depthColorMap = jet(2^8); % used to show depth info
    depthStepSize = 0.25; % mm?

    % export options
    exportAllFigure = 0;
    exportJpg  = 1;
    exportPdf  = 0;
    exportTiff = 0;
    exportPng  = 0;
    exportFig  = 0;

    exportRawTiff = 1;
    exportRawPng = 0;

    openExportFolder = 1;
    resolution = '-r150'; % -r300 -r80
  end

  properties (SetAccess = private)
    % step sizes, calculated automatically from x,y,z using get methods, can't be set!
    dX; dY;
    dR; % average x-y pixels size
  end

  properties
  % defined in base class but this way we can have set/get in sublcasses, which
  % is % needed for FOAM processor
    silent(1,1) {mustBeNumericOrLogical} = false;
    verboseOutput(1,1) {mustBeNumericOrLogical} = true; % more detailed output to workspace...
    verbosePlotting(1,1) {mustBeNumericOrLogical} = false; % more figures...
    figureVisibility(1,:) char {mustBeMember(figureVisibility,{'on','off'})} = 'on';
  end




  % Methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    % class constructor - needs to be in here!
    % note that if first input arg when creating new instance of class is a
    % Maps object then we will create a deep copy of the data, this is neccesary
    % because a simple copy of a handle object only creates a shallow copy
    % and if we don't make it a handle class then things lile M.Norm don't work
    % and we would have to write M = M.Norm which makes things messy again...
    function newMap = Maps(varargin)
      className = class(newMap);
      if nargin
        if isa(varargin{1},className)
          % input was also a maps class, which means we want a new instance
          % of that class containing the same data, so we deep copy the shit out
          % of it!
          oldMap = varargin{1}; % copy data from this "old" Map
          [newMap] = deep_copy_handle_class(newMap,oldMap);
        elseif isstruct(varargin{1}) % ExpData struct
          ExpData = varargin{1};
          full3d  = ExpData.USig.Full3D;
          newMap.x  = ExpData.YPosVec;
          newMap.y  = ExpData.XPosVec;
          newMap.xy = max(full3d,[],3);
        elseif isnumeric(varargin{1}) % 3d array
          % calculate raw MIPs directly from 3d dataset
          full3d = varargin{1};
          [newMap.xy,newMap.depthInfo] = max(full3d,[],3);
          % assign vectors as well if provided
          if nargin == 3
            newMap.x = varargin{2};
            newMap.y = varargin{3};
          elseif nargin == 4
            newMap.x = varargin{2};
            newMap.y = varargin{3};
            % update depth info based on z-values, see set.depthInfo method
            newMap.depthInfo = full3d;
          end
        end
      end
    end

    function saveMaps = saveobj(M)
      M.Frangi = [];
      M.ImFilter = [];
      M.figureHandle = [];
      M.raw = [];
      M.filt = [];
      saveMaps = M;
    end


    % Methods - Declared In Seperate Files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % kinda like a class declaration, with the definition in separate files
    % This way the class definition doesn't get to messy

    % function Crop_Map(M,xRange,yRange)

    % Used all the time, have short cut M.P as well
    function P(M,varargin)
      M.Plot(varargin{:});
    end

    function overlayMap = Overlay_Map(M,overlayMap,overlayColorMap)
      overlayMap = overlay_images(M.xy,overlayMap,overlayColorMap);
    end

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % general set/get functions
  methods
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % XY and related set/get functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods

    % Frangi class is automatically initialized when not done so before!
    function Frangi = get.Frangi(M)
      if isempty(M.Frangi.filt)
        if M.verboseOutput
          fprintf('[Maps] Initializing Frangi filter class.\n')
        end
        M.Frangi = Frangi_Filter(M);
        M.Frangi.filt = M.xy;
        M.Frangi.x = M.x;
        M.Frangi.y = M.y;
        addlistener(M.Frangi,'FiltUpdated',@M.Replace_Filt_With_Frangi);
      end
      % always keep Frangi Filter in Maps class up to date (same xy, x, y,...)
      Frangi = M.Frangi;
    end

    function Replace_Filt_With_Frangi(M,~,~)
      M.filt = M.Frangi.filt;
    end

    function Update_Frangi_Content(M)
      M.Frangi.filt = M.xy;
      M.Frangi.raw = M.xy;
      M.Frangi.x = M.x;
      M.Frangi.y = M.y;
    end

    % Image_Filter class is automatically initialized when not done so before!
    function ImFilter = get.ImFilter(M)
      if isempty(M.ImFilter.filt)
        if M.verboseOutput
          fprintf('[Maps] Initializing image filter class.\n')
        end
        M.ImFilter = Image_Filter(M);
        M.ImFilter.filt = M.xy;
        M.ImFilter.x = M.x;
        M.ImFilter.y = M.y;
        addlistener(M.ImFilter,'FiltUpdated',@M.Replace_Filt_With_ImFilt);
      end
      ImFilter = M.ImFilter;
    end

    function Replace_Filt_With_ImFilt(M,~,~)
      M.filt = M.ImFilter.filt;
    end

    function Update_FiltIm_Content(M)
      M.ImFilter.filt = M.xy;
      M.ImFilter.raw = M.xy;
      M.ImFilter.x = M.x;
      M.ImFilter.y = M.y;
    end


    % Image_Filter class is automatically initialized when not done so before!
    function AVA = get.AVA(M)
      if isempty(M.AVA.xy)
        if M.verboseOutput
          fprintf('[Maps] Initializing vessel analysis class.\n')
        end
        M.AVA = Vessel_Analysis(M);
        M.AVA.xy = M.xy;
        M.AVA.x = M.x;
        M.AVA.y = M.y;
      end
      AVA = M.AVA;
    end

    % get position vectos, always return as double! ----------------------------
    function x = get.x(M)
      %Note: type conversion is very very fast in Matlab, especially if the
      % type of the variable is already correct (i.e. single(singleVar))
      % takes basically NO time and it takes longer to check first using isa
      if isempty(M.xy) && isempty(M.x)
%         warning('No image or x data given!');
        x = [];
      elseif isempty(M.x)
        nX = size(M.xy,2);
        x = 1:nX;
      else
        x = double(M.x);
      end
    end

    function y = get.y(M)
      %Note: type conversion is very very fast in Matlab, especially if the
      % type of the variable is already correct (i.e. single(singleVar))
      % takes basically NO time and it takes longer to check first using isa
      if isempty(M.xy) && isempty(M.y)
%         warning('No image or x data given!');
        x = [];
      elseif isempty(M.y)
        nY = size(M.xy,1);
        y = 1:nY;
      else
        y = double(M.y);
      end
    end

    % get area of Map, it's fairly simple map ----------------------------------
    function area = get.area(M)
      %Note: see above
      lengthX = max(M.x) - min(M.x);
      legnthY = max(M.y) - min(M.y);
      area = lengthX*legnthY;
    end

    % calculate step sizes based on x and y vectors ----------------------------
    function dX = get.dX(M)
      if isempty(M.x)
        % short_warn('Need to define x-vector (M.x) before I can calulate the step size!');
        dX = [];
      else
        dX = mean(diff(M.x));
      end
    end

    function dY = get.dY(M)
      if isempty(M.x)
        % short_warn('Need to define x-vector (M.y) before I can calulate the step size!');
        dY = [];
      else
        dY = mean(diff(M.y));
      end
    end


    % calculate an avearge xy step size, warn if error large -------------------
    function dR = get.dR(M)
        stepSize = mean([M.dX,M.dY]);
        stepSizeDiff = 100*abs(M.dX-M.dY)/stepSize; % [in % compared to avarage step size]
        allowedStepsizeDiff = 3; % [in %]
        if stepSizeDiff > allowedStepsizeDiff
          short_warn('Large difference in step size between x and y!')
        end
        dR = stepSize;
    end


    function set.xy(M,map)
      % set raw map on first asginement of xy map
      if isempty(M.xy) && isempty(M.raw)
        M.raw = map;
      end
      M.xy = map;
      % update filter classes when changing original xy
      if ~isempty(M.Frangi.filt)
        M.Update_Frangi_Content();
      end
      if ~isempty(M.ImFilter.filt)
        M.Update_FiltIm_Content();
      end
    end

    function set.depthInfo(M,inputArg)
      if isstruct(inputArg)
        ExpData = inputArg;
        [~,depthData] = max(ExpData.USig.Full3D,[],3);
        depthData = depthData*meano(diff(-M.z));
        M.depthInfo = depthData - min(depthData(:));
      elseif ndims(inputArg)==3 % set the depth info directly
        [~,depthData] = max(inputArg,[],3);
        depthData = depthData*meano(diff(-M.z));
        depthData = depthData - max(depthData(:));
        % depthData = depthData - min(depthData(:));
        M.depthInfo = depthData;
      elseif ismatrix(inputArg) % set the depth info directly
        M.depthInfo = inputArg;
      else
        M.depthInfo = [];
        short_warn('Could not set depth info!');
      end
    end

  end % end of methods definition
  %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
end % end of class definition
