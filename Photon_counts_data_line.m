clc; clear;
% parameters
mu = 0.5; % Mean Number of Photons/Pulse
alpha = 0.2; % Attenuation in fiber in dB/Km
delta_f = 1e3; % Linewidth in Hz
d_t = 1e-9; % 1/Bit rate
R_b = 1e9; % Sequence length
L = 0:1:150; % Length of Fiber
t_B = 0.5; % Transmittance of BS
loss_MZI = 1 * 10^(-0.2); % 2 dB loss in MZI
theta = 0; % Phase difference of two consecutive pulses
eta = 0.2; % Efficiency of SPD
P_d = 2e-7; % Dark Cout Probability/Pulse in SPD
t_d = 10e-9; % Dead Time in SPD
f_decoy = 0.2; % Probability used to generate the decoy state
duty_cycle_TTL = 0.75; % Duty cycle of TTL pulses
% Phase Noise at LASER
sigma = sqrt(2*pi*delta_f*d_t);
%Channel transmittance
eta_channel = 10.^(- alpha * L /10);
Photon_count_after_channel = mu * 10.^(- alpha * L /10) * R_b;
%% DATA LINE 
% After Beam Splitter
Photon_count_after_BS = mu * 10.^(- alpha * L /10)* R_b * t_B;
% Photon Counts considering the SPD efficiency and dark count rate
Photon_count_after_D_d = Photon_count_after_BS .* eta + P_d * R_b;
% Effective time difference between two consecutive pulses at data line
effective_time_difference_D_d = 1./(Photon_count_after_D_d) + t_d;
% Considering the Duty Cycle of TTL Pulses at D_d
effective_counts_D_d = ((1./effective_time_difference_D_d)).* duty_cycle_TTL;
% Graphs at Data Line
figure
plot(L,effective_counts_D_d, '-', 'Color', [0.80 0.30 0.00], 'LineWidth', 3);
xlabel('Length of Fiber (Km)' , 'FontSize', 13,'FontWeight', 'bold')
ylabel('Photon Counts at D_d (cps)' , 'FontSize', 13,'FontWeight', 'bold')
grid on;
xlim([1 150]);
ylim([-1000 26000000]);
grid on;
box on;
set(gca, 'FontSize', 12,'LineWidth', 1.2, 'FontWeight', 'bold');
hold off;



