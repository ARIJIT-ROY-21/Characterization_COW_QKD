clc; clear;
% parameters
mu = 0.5; % Mean Number of Photons/Pulse
alpha_values = [3.8 9.64 28.6]; % Attenuation at Free Space in dB/Km
delta_f = 1e3; % Linewidth in Hz
d_t = 1e-9; % 1/Bit rate
R_b = 1e9; % Bit Rate
D_t = 0.00005; % Transmitter Aperture in Km
D_r = 0.00005; % Recevier Aperture in Km
D = 0.000025; % Beam Divergence in radian
L_FSO = 0:0.1:10; % Transmission Distance in Km
t_B = 0.5; % Transmittance of BS
loss_MZI = 1 * 10^(-0.2); % 2 dB loss in MZI
theta = 0; % Phase difference of two consecutive pulses
eta = 0.2; % Efficiency of detector
P_d = 2e-7; % Dark Cout probability/Pulse in detector
t_d = 10e-9; % Dead Time in detector
f_decoy = 0.2; % Probability used to generate the decoy state
duty_cycle_TTL = 0.75; % Duty cycle of TTL pulses
% Phase Noise at LASER
sigma = sqrt(2*pi*delta_f*d_t);
%Channel transmittance
lines = {'-','--','-.'};
% Store plot handles
pV = gobjects(length(alpha_values),1);
pQ = gobjects(length(alpha_values),1);
figure;
hold on;
for k = 1:length(alpha_values)

    alpha = alpha_values(k);
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
effective_counts_SPD_0 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL;
effective_counts_SPD_1 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL;
% Considering the Probability factor
total_counts_D_M1 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL * (2.*f_decoy + (1-f_decoy).^2./2);
total_counts_D_M2 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL * (2.*f_decoy + (1-f_decoy).^2./2);
% Visibility
V = (total_counts_D_M1 - total_counts_D_M2)./(total_counts_D_M1 + total_counts_D_M2);
% Quantum Bit Error Rate in percentage
Q_0 = (1 - V)./2;
Q = (1 - V).*100./2;
 yyaxis left
 pV(k) = plot(L_FSO, V,'b','LineStyle', lines{k},'LineWidth', 2);
  ylabel('Visibility (V)', 'FontSize', 16, 'FontWeight', 'bold');
  ylim([0.72 1.01]);
yyaxis right
   pQ(k) =  plot(L_FSO,Q,'r','LineStyle',lines{k},'LineWidth',2);
     ylabel('QBER (%)', 'FontSize', 16, 'FontWeight', 'bold');
     ylim([-1 15]);
end

legend([pV(1) pV(2) pV(3) pQ(1) pQ(2) pQ(3)],'Haze(V)','Rain(V)','Fog(V)','Haze(QBER)','Rain(QBER)','Fog(QBER)','Location', 'east');

   
xlabel('Transmission Distance(Km)', 'FontSize', 16, 'FontWeight', 'bold');
xlim([0 7]);
grid on;
box on;
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');