P = PosData();
P.Load_Raw_Data(filePath);

% then get some simple pos data:
P.tS = (0:P.nShots-1)*P.dt; % based on laser PRF
P.xSSmooth = movmean(P.xS,P.smoothWidth);
P.xVel = gradient(P.xSSmooth,P.dt);
% or, also getting the y-trajectory:
P.Process_Sampled_Positions();
