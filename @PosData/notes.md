# PosData Workflows

## 1 - raw-x-pos measured for calibration (few cycles)
- find start/end of oscillation
- check for correct ROI (center, width) and velocity
  -> recal if out of bounds
- get period of B-scan and number of B-scans based on ROI and oversampling and
  program x-stage macro accordingly
- calculate y-velocity based on number of B-scans and B-scan period, setup
  slow-stage accordingly,
    -> use new formula for that to take distance and acceleration into account
     to get correct velocity!

## 1 - raw-x-pos measured for scan
- find start/end of oscillation
- check for correct ROI (center, width) and velocity
- get period of B-scan and number of B-scans
- calculate y-stage position profile based on programmed speed and time
  -> it's possible the stage calibration was bad and y-stage finished prematurely
  or too late...

- formula to get stage speed taking into account fixed acc. and width/movement
v = 1/2*(a*t-sqrt(a)*sqrt(a*t^2-4*s)) % holy fuck this actually works!
% difference to vLin = s/t is very small for long, slow movement!
