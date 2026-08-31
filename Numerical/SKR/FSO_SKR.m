clc; clear;
% parameters
mu = 0.5; % Mean Number of Photons/Pulse
alpha_values = [3.8 9.64 28.6]; % Attenuation at Free Space in dB/Km
delta_f = 1e3; % Linewidth in Hz
d_t = 1e-9; % 1/Bit rate
R_b = 1e9; % Bit Rate
D_t = 0.00005; % Transmitter Aperture in Km
D_r = 0.00005; % Recevier Aperture in Km
D = 0.000025; % Beam Divergence
L_FSO = 0:0.001:7; % Transmission Distance in Km
t_B = 0.5; % Transmittance of BS
loss_MZI = 1 * 10^(-0.2); % 2 dB loss in MZI
theta = 0; % Phase difference of two consecutive pulses
eta = 0.5; % Efficiency of Detector
P_d = 2e-7; % Dark Cout Rate in Detector
t_d = 10e-9; % Dead Time in Detector
f_decoy = 0.2; % Probability used to generate the decoy state
duty_cycle_TTL = 0.75; % Duty cycle of TTL pulses
f = 1.16;

figure;
hold on;
colors = {[1.0 0.5 0.0]    % Orange
          [1.0 0.8 0.0]    % Yellow
          [0.5 0.0 0.5]    % Purple
};
lines  = {'-','--','-.'};
for k = 1:length(alpha_values)
    alpha = alpha_values(k);
% Phase Noise at LASER
sigma = sqrt(2*pi*delta_f*d_t);
%Channel transmittance
eta_channel = (D_r./(D_t + D.*L_FSO)).^2 .* 10.^(- alpha .* L_FSO /10);
Photon_count_after_channel = mu * eta_channel * R_b;
%% DATA LINE %%
% After Beam Splitter
Photon_count_after_BS = mu * eta_channel* R_b * t_B;
% Photon Counts considering the SPD efficiency and dark count rate
Photon_count_after_D_d = Photon_count_after_BS .* eta + P_d * R_b;
% Effective time difference between two consecutive pulses at data line
effective_time_difference_D_d = 1./(Photon_count_after_D_d) + t_d;
% Considering the Duty Cycle of TTL Pulses at D_d
effective_counts_D_d = ((1./effective_time_difference_D_d)).* duty_cycle_TTL;
%% MONITORING LINE%%
% After Beam Splitter
Photon_count_after_BS = mu *eta_channel* R_b * (1-t_B);
% Photon Counts after MZI
Photon_Count_MZI_Upper = loss_MZI * mu * eta_channel*  R_b * (1-t_B) * ((1+ 1*exp(-(sigma.^2)./2) * cos(theta))/2);
Photon_Count_MZI_Lower = loss_MZI * mu * eta_channel*  R_b * (1-t_B) * ((1- 1*exp(-(sigma.^2)./2) * cos(theta))/2);
% No. of Photons reach at the SPDs
Photon_Count_before_SPD_0 = Photon_Count_MZI_Upper;
Photon_Count_before_SPD_1 = Photon_Count_MZI_Lower;
% Photon Couts considering the SPD efficiency and dark count rate
Photon_Count_after_SPD_0 = Photon_Count_before_SPD_0 * eta + P_d * R_b;
Photon_Count_after_SPD_1 = Photon_Count_before_SPD_1 * eta + P_d * R_b;
% Effective time difference between two consecutive pulses
effective_time_difference_SPD_0 = 1./(Photon_Count_after_SPD_0) + t_d;
effective_time_difference_SPD_1 = 1./(Photon_Count_after_SPD_1) + t_d;
% Considering the Duty Cycle of TTL Pulses
effective_counts_SPD_0 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL *(2.*f_decoy + (1-f_decoy).^2./2);;
effective_counts_SPD_1 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL *(2.*f_decoy + (1-f_decoy).^2./2);;
% Considering the Probability factor
total_counts_D_M1 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL;
total_counts_D_M2 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL;
% Visibility
V = (total_counts_D_M1 - total_counts_D_M2)./(total_counts_D_M1 + total_counts_D_M2);
% Quantum Bit Error Rate in percentage
Q_0 = (1 - V)./2;
Q = (1 - V).*100./2;
% No of counts after Sifting
R_s = effective_counts_D_d * (1 - f_decoy);
% Eve's Information
I_Eve =  0;
% Shanon Entropy
H2 = @(x) -(x .* log2(x) + (1 - x) .* log2(1 - x));
H2 = @(x) real((x==0 | x==1).*0 + (x>0 & x<1).*H2(x));
% Secret key rate/s
R = R_s .* (1 - f .* H2(Q_0) - I_Eve);
R(R < 1e-10) = eps;  
%% Distance in meters
    L_meter = L_FSO*1000;
    semilogy(L_meter, R,'Color', colors{k},'LineStyle', lines{k},'LineWidth', 2);
set(gca, 'YScale', 'log');
end
xlabel('Transmission Distance (m)');
xlim([0 7000]);
ylabel('Secret Key Rate (bits/s)');
ylim([1e-2 1e8]);
legend('Haze','Rain','Fog','Location','northeast');
grid on;
box on;
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');
hold off;