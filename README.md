# DRDO_Internship

https://fail0verflow.com/blog/2014/proxmark3-fpga-peak-detection/
![image](https://github.com/user-attachments/assets/61c7daab-bccf-42d4-a3bd-9a0296e1fac2)
reference https://github.com/leandcesar/PeakDetection/tree/master
# Algorithm
It is based on the principle of dispersion: if a new datapoint is a given x number of standard deviations away from some moving average, the algorithm signals (also called z-score).

The algorithm takes 3 inputs:

lag: is the lag of the moving window. This parameter determines how much your data will be smoothed and how adaptive the algorithm is to changes in the long-term average of the data. The more stationary your data is, the more lags you should include. If your data contains time-varying trends, you should consider how quickly you want the algorithm to adapt to these trends.

threshold: this parameter is the number of standard deviations from the moving mean above which the algorithm will classify a new datapoint as being a signal. This parameter should be set based on how many signals you expect. The threshold therefore directly influences how sensitive the algorithm is and thereby also how often the algorithm signals.

influence: is the z-score at which the algorithm signals. This parameter determines the influence of signals on the algorithm's detection threshold. If put at 0, signals have no influence on the threshold, such that future signals are detected based on a threshold that is calculated with a mean and standard deviation that is not influenced by past signals. You should put the influence parameter somewhere between 0 and 1, depending on the extent to which signals can systematically influence the time-varying trend of the data.


## Purpose
Detects peaks in a signal based on the z-score method, comparing each new sample to the moving average and standard deviation of previous samples. Supports detection of both positive and negative peaks with configurable sensitivity.

1. Constants

const int DEFAULT_LAG = 32;
const int DEFAULT_THRESHOLD = 2;
const double DEFAULT_INFLUENCE = 0.5;
const double DEFAULT_EPSILON = 0.01;
lag: Number of previous points used to calculate mean and standard deviation.

threshold: How many standard deviations a point must deviate to be considered a peak.

influence: How much the detected peak influences the filtered data stream.

EPSILON: Small value to prevent divide-by-zero errors or near-zero standard deviation.

2. Constructor / Destructor

PeakDetection::PeakDetection();
PeakDetection::~PeakDetection();
Initializes default values.

Allocates memory in begin().

Cleans up memory in destructor.

3. Initialization

void PeakDetection::begin();
void PeakDetection::begin(int lag, int threshold, double influence);
Allocates arrays data, avg, and std of size lag + 1.

Initializes them to zero.

4. Core Detection Logic


double PeakDetection::add(double newSample);
This is the heart of the algorithm, executed for each new data point.

Steps:
Determine current (i) and next (j) buffer positions using modulo.

Calculate deviation of the new sample from the current average.

Check if it's a peak:

If deviation > threshold × std → positive peak

If deviation < -threshold × std → negative peak

Update data[j]:

If peak → blend newSample with data[i] using influence

Else → just store the newSample

Recalculate moving average and standard deviation for j.

Store peak status (1 = positive, -1 = negative, 0 = none).

Return standard deviation for analysis/debugging.

5. Supporting Functions
double getFilt();
Returns the current filtered average.

int getPeak();
Returns the peak status after last sample:

1 = positive peak

-1 = negative peak

0 = no peak

double getAvg(int start, int len);
Computes the moving average over len samples starting from start.

double getPoint(int start, int len);
Computes the mean of squares (used for standard deviation).

double getStd(int start, int len);
Calculates standard deviation using:

![image](https://github.com/user-attachments/assets/a352b8a9-b776-474d-9536-6e9a6974a6bf)

​
 
Handles near-zero values using EPSILON to avoid instability.

void setEpsilon(double epsilon);
Sets a new minimum bound for standard deviation.

double getEpsilon();
Returns the current EPSILON value.
