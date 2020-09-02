function Copy_Settings(NewObj,OldObj)
  NewObj.mode = OldObj.mode;  
  NewObj.dt = OldObj.dt;  
  NewObj.prf = OldObj.prf;  
  NewObj.power = OldObj.power;  
  NewObj.wavelength = OldObj.wavelength;  
  NewObj.doRemoveNoise = OldObj.doRemoveNoise;  
  NewObj.sumBased = OldObj.sumBased;  
  NewObj.noiseWindow = OldObj.noiseWindow;  
  NewObj.signalWindow = OldObj.signalWindow;  
  NewObj.maxFitOrder = OldObj.maxFitOrder;  
end
