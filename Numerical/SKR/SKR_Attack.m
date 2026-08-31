clc; clear;
% parameters
mu = 0.5; % Mean Number of Photons/Pulse
alpha = 0.2; % Attenuation in fiber in dB/Km
delta_f = 1e3; % Linewidth in Hz
d_t = 1e-9; % 1/Bit rate
R_b = 1e9; % Bit Rate
L = 0:0.5:260; % Length of Fiber in Km
t_B = 0.5; % Transmittance of BS
loss_MZI = 1 * 10^(-0.2); % 2 dB loss in MZI
theta = 0; % Phase difference of two consecutive pulses
eta = 0.2; % Efficiency of Detectror
P_d = 2e-7; % Dark Cout Probability/Pulse Detector
t_d = 10e-9; % Dead Time in Detector
t_BSE = 0.8 %Transmittance of Eve's BS
f_decoy = 0.2; % Probability used to generate the decoy state
duty_cycle_TTL = 0.75; % Duty cycle of TTL pulses
f = 1.16;
% Phase Noise at LASER
sigma = sqrt(2*pi*delta_f*d_t);
%Channel transmittance
eta_channel = 10.^(- alpha * L /10);
Photon_count_after_channel = mu * 10.^(- alpha * L /10) * R_b;
%% DATA LINE %%
% After Beam Splitter
Photon_count_after_BS = mu * 10.^(- alpha * L /10)* R_b * t_B;
% Photon Counts considering the SPD efficiency and dark count rate
Photon_count_after_D_d = Photon_count_after_BS .* eta + P_d * R_b;
% Effective time difference between two consecutive pulses at data line
effective_time_difference_D_d = 1./(Photon_count_after_D_d) + t_d;
% Considering the Duty Cycle of TTL Pulses at D_d
effective_counts_D_d = ((1./effective_time_difference_D_d)).* duty_cycle_TTL;
%% MONITORING LINE%%
% After Beam Splitter
Photon_count_after_BS = mu * 10.^(- alpha * L /10)* R_b * (1-t_B);
% Photon Counts after MZI
Photon_Count_MZI_Upper = loss_MZI * mu * 10.^(- alpha * L /10)*  R_b * (1-t_B) * ((1+ 1*exp(-(sigma.^2)./2) * cos(theta))/2);
Photon_Count_MZI_Lower = loss_MZI * mu * 10.^(- alpha * L /10)*  R_b * (1-t_B) * ((1- 1*exp(-(sigma.^2)./2) * cos(theta))/2);
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
% No of counts after Sifting
R_s = effective_counts_D_d * (1 - f_decoy);
% Binary entropy function with edge case handling
H2 = @(x) -(x .* log2(x) + (1 - x) .* log2(1 - x));
H2 = @(x) real((x==0 | x==1).*0 + (x>0 & x<1).*H2(x));
% No Attack
I_Eve0 = zeros(size(L));
R0 = R_s .* (1 - f.*H2(Q_0) - I_Eve0);
R0(R0<=0)=eps;
% Only BS Attack
I_Eve_BS = mu*(1-t_BSE).*10^(-0.2*1/10);
R_BS = R_s .* (1 - f.*H2(Q_0) - I_Eve_BS);
R_BS(R_BS<=0)=eps;
% Only IR Attack
I_Eve_IR = (1-V).*(1+exp(-mu.*eta_channel))./(2*exp(-mu.*eta_channel));
R_IR = R_s .* (1 - f.*H2(Q_0) - I_Eve_IR);
R_IR(R_IR<=0)=eps;
% Under BS and IR Attack
I_Eve_Total = I_Eve_BS + I_Eve_IR;
R_Total = R_s .* (1 - f.*H2(Q_0) - I_Eve_Total);
R_Total(R_Total<=0)=eps;
figure;
semilogy(L, R0,     'Color',[1.00 0.00 0.00], 'LineStyle','-',  'LineWidth',2); hold on;
semilogy(L, R_BS,   'Color',[0.00 0.45 0.74], 'LineStyle','-.', 'LineWidth',2);
semilogy(L, R_IR,   'Color',[0.93 0.69 0.13], 'LineStyle',':',  'LineWidth',2);
semilogy(L, R_Total,'Color',[0.00 0.20 0.50], 'LineStyle','--', 'LineWidth',2);
xlabel('Length of Fiber (Km)');
ylabel('Secret Key Rate (bits/s)');
legend('No Eve','Under BS Attack','Under IR Attack','Under both BS + IR Attack','Location','northeast');
grid on;
xlim([50 255]);
ylim([1e0 1e7]);
ax_main = gca;
box on;
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');
hold off;
%% Inset
ax_inset = axes('Position',[0.18 0.20 0.30 0.25]);
copyobj(findobj(ax_main,'Type','line'),ax_inset);
set(ax_inset,'YScale','log');
xlim(ax_inset,[150 151]);
ylim(ax_inset,[2.32e4 2.85e4]);
grid(ax_inset,'on');
box(ax_inset,'on');
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');
hold off;

