Data Sample_1 Sample_2;

Set YourSASDataSet;

If uniform(today()) <= 0.5 Then Output Sample_1;

              Else Output Sample_2;

Run;

%Let ClusterCount = 3000;

Proc Fastclus Data=Sample_1 Out=Sample_1_Clusters

Maxclusters=&ClusterCount.

Outstat=ClusterCentres;

Var Longitude Latitude Meter_Count;

Run;
/*  We use the SAS procedure FastClus on the first set of data.
This is a clustering procedure which divides up the sample space into a given number of clusters.
The cluster centers are chosen by minimizing the sum of squares distance from each observation to the center of its nearest
cluster. We use 3,000 clusters in this example*/

Proc Summary Data=Sample_1_Clusters nway missing;

Class Cluster;

Var TargetVar;

Output Out=MeanTable

(Rename = (TargetVar = P_TargetVar))

Mean=;

Run;

Data ClusterCentres(Drop=_TYPE_ OVER_ALL CLUSTER Consumption);

Set ClusterCentres(Where=(_TYPE_= "CENTER"));

Run;

Proc Transpose Data=ClusterCentres Out=Temp_ClusterCentres; Run;

Proc sql noprint;

Select _NAME_

Into :Name_List separated by '|'

From Temp_ClusterCentres;

Quit;

%Macro ReadInParameters();

%Do j = 1 %To &ClusterCount.;

%Global Parameter_List_&j.;

Proc sql noprint;

Select Col&j.

Into :Parameter_List_&j. separated by '|'

From Temp_ClusterCentres;

Quit;

%End;

%Mend;

%ReadInParameters();

%Macro Distance(k, Parameter_List);

Temp_Distance = (1

%Do j = 1 %To 3;

%Let Factor = %Scan(&Name_List., &j., "|");

%Let Parameter = %Scan(&Parameter_List., &j., "|");

+ (&Factor. - &Parameter.) ** 2

%End;

-1);

%Mend;

%Macro CalculateDistance();

Data Sample_2_Testing;

Set Sample_2;

%Distance(1, &Parameter_List_1);

Cluster = 1;

Distance = Temp_Distance;

Run;

%Do k = 2 %To &ClusterCount.;

Data Sample_2_Testing(Drop=Temp_Distance);

Set Sample_2_Testing;

%Distance(&k., &Parameter_List_&k.);

If Temp_Distance < Distance Then Do;

              Distance = Temp_Distance;

              Cluster = &k.;

              End;

Run;

%End;

%Mend;

%CalculateDistance();

Proc Sql noprint;

Create Table Merged as

Select a.*, b.P_TargetVar

From Sample_2_Testing a

Left Join MeanTable b

On a.Cluster = b.Cluster;

Quit;

Data Merged; Set Merged;

Within_010Percent = (abs(P_TargetVar / TargetVar - 1) < 0.1);

Run;

Proc Freq data=Merged;

Table Within_010Percent;

Run;
