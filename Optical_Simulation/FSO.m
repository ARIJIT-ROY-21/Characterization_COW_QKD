clc; clear;
% parameters
mu = 0.5074; % Mean Number of Photons/Pulse
alpha_values = [3.8 9.64 28.6]; % Attenuation at Free Space in dB/Km
delta_f = 1e3; % Linewidth in Hz
d_t = 1e-9; % 1/Bit rate
R_b = 262144; % Sequence length
D_t = 0.00005; % Transmitter Aperture in Km
D_r = 0.00005; % Recevier Aperture in Km
D = 0.000025; % Beam Divergence
L_FSO = 0:0.1:5.1; % Transmission Distance
t_B = 0.5; % Transmittance of BS
loss_MZI = 1 * 10^(0); % 2 dB loss in MZI
theta = 0; % Phase difference of two consecutive pulses
eta = 0.6; % Efficiency of Detector
P_d = 2e-7; % Dark Cout Rate in Detector
t_d = 10e-9; % Dead Time in Detector
duty_cycle_TTL = 1; % Duty cycle of TTL pulses
% Phase Noise at LASER
sigma = sqrt(2*pi*delta_f*d_t);
colors = {'r','b',[0.35 0.05 0.45]};
weather_names = {'Haze','Fog','Rain'};
line_styles = {'-','--','-.'};
filename = 'FSO_simu.xlsx';
data = readtable(filename);
L_FSO_excel = data{:,1};
Q_excel_haze = data{:,5};
Q_excel_fog  = data{:,9};
Q_excel_rain = data{:,13};
Q_excel_all = {Q_excel_haze, Q_excel_fog, Q_excel_rain};
figure;
hold on;
for k = 1:length(alpha_values)

    alpha = alpha_values(k);
eta_channel = (D_r./(D_t + D.*L_FSO)).^2 .* 10.^(- alpha .* L_FSO /10);
Photon_count_after_channel = mu * eta_channel * R_b;
% DATA LINE 
% After Beam Splitter
Photon_count_after_BS = mu * eta_channel* R_b * t_B;
% Photon Counts considering the SPD efficiency and dark count rate
Photon_count_after_D_d = Photon_count_after_BS .* eta + 250;
% Effective time difference between two consecutive pulses at data line
effective_time_difference_D_d = 1./(Photon_count_after_D_d) + t_d;
% Considering the Duty Cycle of TTL Pulses at D_d
effective_counts_D_d = ((1./effective_time_difference_D_d)).* duty_cycle_TTL;
% MONITORING LINE
% After Beam Splitter
Photon_count_after_BS = mu *eta_channel* R_b * (1-t_B);
% Photon Counts after MZI
Photon_Count_MZI_Upper = loss_MZI * mu * eta_channel*  R_b * (1-t_B) * ((1+ 1*exp(-(sigma.^2)./2) * cos(theta))/2);
Photon_Count_MZI_Lower = loss_MZI * mu * eta_channel*  R_b * (1-t_B) * ((1- 1*exp(-(sigma.^2)./2) * cos(theta))/2);
% No. of Photons reach at the SPDs
Photon_Count_before_SPD_0 = Photon_Count_MZI_Upper;
Photon_Count_before_SPD_1 = Photon_Count_MZI_Lower;
% Photon Couts considering the SPD efficiency and dark count rate
Photon_Count_after_SPD_0 = Photon_Count_before_SPD_0 * eta + 250;
Photon_Count_after_SPD_1 = Photon_Count_before_SPD_1 * eta + 250;
% Effective time difference between two consecutive pulses
effective_time_difference_SPD_0 = 1./(Photon_Count_after_SPD_0) + t_d;
effective_time_difference_SPD_1 = 1./(Photon_Count_after_SPD_1) + t_d;
% Considering the Duty Cycle of TTL Pulses
effective_counts_SPD_0 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL;
effective_counts_SPD_1 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL;
% Considering the Probability factor
total_counts_D_M1 = ((1./effective_time_difference_SPD_0))* duty_cycle_TTL;
total_counts_D_M2 = ((1./effective_time_difference_SPD_1))* duty_cycle_TTL;
% Visibility
V = (total_counts_D_M1 - total_counts_D_M2)./(total_counts_D_M1 + total_counts_D_M2);
% Quantum Bit Error Rate in percentage
Q_0 = (1 - V)./2;
Q = (1 - V).*100./2;
% Plot
plot(L_FSO, Q, 'Color', colors{k}, 'LineStyle', line_styles{k}, 'LineWidth', 2.5, 'DisplayName', [weather_names{k} ' - Numerical Model']);
    Q_excel = Q_excel_all{k};
simulation_colors = {'r', 'b', [0.35 0.05 0.45]};
plot(L_FSO_excel, Q_excel,'o','Color', simulation_colors{k},'MarkerFaceColor', simulation_colors{k},'MarkerSize', 7,'LineWidth', 1.5,'DisplayName', [weather_names{k} ' - Simulation Result']);

end
xlabel('Transmission Distance (Km)','FontSize', 13,'FontWeight', 'bold');
ylabel('QBER (%)','FontSize', 13,'FontWeight', 'bold');
legend('Location','southeast');
grid on;
box on;
set(gca, 'FontSize', 12,'LineWidth', 1.2);
xlim([0 5.1]);
hold off;