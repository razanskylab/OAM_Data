function Get_Vessel_Stats(Maps)
  % Get_Vessel_Stats returns vessels statisitics in microns
  % LengthStats - statisitics on vessel lengths
  % DiameterStats - statisitics on vessel diameters
  % TurtosityStats -  statisitics on vessel turtosity (arc-length/(endpoint distance))
    % each with the follwing statisitics:
    %  min = min(vect); % Smallest elements in array
    %  max = max(vect); % max	Largest elements in array
    %  bounds = bounds(vect); % bounds	Smallest and largest elements
    %  mean = mean(vect);   % mean	Average or mean value of array
    %  median = median(vect); % median	Median value of array
    %  mode = mode(vect); % mode	Most frequent values in array
    %  std = std(vect); % std	Standard deviation
    %  stdPer = std(vect)/mean(vect); % std	Standard deviation
    %  var = var(vect); % var	Variance
    %  nEntries = numel(vect); % number of vector elements
  % nVessels - total vessels found
  % totalLength - sum of all vessels

  t1 = tic;
  fprintf('Analyzing vessels using AOVA...\n')

  if Maps.verboseOutput
    print_vessel(); % print a vessel, pretty self explanatory really...
  end

  pxToMicron = Maps.dR*1e3; % return vessels length and diameters in microns!

  % Perform actual AOVA/ARIA vessels analysis

  Maps = aova_analysis(Maps);
  % all vessels is a list with each cell entry giving info about indivd. vessels
  % vessels consist of a center line, edges and have a length and such
  % get_diameter_stats calculates the statisitics of each ind. vessels diameters
  % using the seperate segements of each vessel
  AllVessels =   Maps.VesselData.vessel_list;
  [IndDiameterStats] = get_diameter_stats(AllVessels);
  allLengths = cell2mat({AllVessels.length_cumulative})*pxToMicron;
  allStraighLengths = cell2mat({AllVessels.length_straight_line})*pxToMicron;
  allDiameters = [IndDiameterStats.mean]*pxToMicron;
  allTurtosities = calculate_turtosity(allLengths,allStraighLengths);

  % get statisitics for difference measures
  if Maps.verboseOutput
    fprintf('   Found vessels with the following properties:\n')
    VesselStats.LengthStats = get_descriptive_stats(allLengths,1,'length','micron');
    VesselStats.DiameterStats = get_descriptive_stats(allDiameters,1,'diameter','micron');
    VesselStats.TurtosityStats = get_descriptive_stats(allTurtosities,1,'turtosity','');
  else
    VesselStats.LengthStats = get_descriptive_stats(allLengths,0);
    VesselStats.DiameterStats = get_descriptive_stats(allDiameters,0);
    VesselStats.TurtosityStats = get_descriptive_stats(allTurtosities,0);
  end

  % Vessel Data Relevant Infos ---------------------------------------------------
  VesselStats.nVessels = Maps.VesselData.num_vessels;
  VesselStats.nBranches = Maps.VesselData.nBranches;
  VesselStats.totalLength = sum(allLengths);
  % vessel coverage in percent
  % coverage defined as nVesselPixel/nTotalPixel
  VesselStats.vesselCoverage = sum(Maps.bin(:))/numel(Maps.bin)*100;
  % vessel area density, defined as nVessel/area
  VesselStats.vesselAreaDensity =   VesselStats.nVessels/Maps.area;

  Maps.VesselStats = VesselStats;
  % vesselDiameters = remove_simple_outliers(vesselDiameters);
  if Maps.verbosePlotting
    Maps.Plot_Aova_Result();
    distFig('Screen','Left','Transpose',true);
  end


  fprintf('Vessels analysis completed in %2.2f s\n',toc(t1));
  % done(toc(t1));
end
