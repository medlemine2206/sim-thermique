% ============================================================
%  SIMULATEUR THERMIQUE — Plaque métallique
%  Mohamed Lemine Ahmed Jeddou | CY Tech | 2026
%
%  Modèle physique :
%    m * Cp * dT/dt = P - h * A * (T - T_ext)
%
%  Résolution numérique par méthode d'Euler explicite
% ============================================================

clc; clear; close all;

% ── 1. PARAMÈTRES UTILISATEUR ────────────────────────────────

% Choix du matériau (1=Aluminium, 2=Acier, 3=Cuivre, 4=Titane)
choix_materiau = 1;

% Puissance injectée (W)
P = 100;

% Température extérieure (°C)
T_ext = 20;

% Dimensions de la plaque (m)
longueur = 0.2;   % 20 cm
largeur  = 0.1;   % 10 cm
epaisseur = 0.005; % 5 mm

% Coefficient de convection h (W/m²·K)
% Convection naturelle air : 5-25 W/m²·K
h = 10;

% Température initiale (°C)
T0 = T_ext;

% Durée de simulation (s)
t_fin = 600;   % 10 minutes

% Pas de temps (s)
dt = 0.5;

% ── 2. BASE DE DONNÉES MATÉRIAUX ────────────────────────────

materiaux = struct();

% Aluminium 2024
materiaux(1).nom  = 'Aluminium';
materiaux(1).rho  = 2700;     % densité (kg/m³)
materiaux(1).Cp   = 900;      % capacité thermique (J/kg·K)
materiaux(1).k    = 237;      % conductivité thermique (W/m·K)
materiaux(1).couleur = [0.7 0.7 0.9];

% Acier inox
materiaux(2).nom  = 'Acier';
materiaux(2).rho  = 7800;
materiaux(2).Cp   = 500;
materiaux(2).k    = 16;
materiaux(2).couleur = [0.5 0.5 0.5];

% Cuivre
materiaux(3).nom  = 'Cuivre';
materiaux(3).rho  = 8960;
materiaux(3).Cp   = 385;
materiaux(3).k    = 401;
materiaux(3).couleur = [0.9 0.5 0.2];

% Titane
materiaux(4).nom  = 'Titane';
materiaux(4).rho  = 4510;
materiaux(4).Cp   = 520;
materiaux(4).k    = 22;
materiaux(4).couleur = [0.6 0.4 0.8];

mat = materiaux(choix_materiau);

% ── 3. CALCULS GÉOMÉTRIQUES ET THERMIQUES ───────────────────

% Volume et masse
V = longueur * largeur * epaisseur;      % m³
m = mat.rho * V;                          % kg

% Surface d'échange (2 faces principales)
A = 2 * longueur * largeur;              % m²

fprintf('=== SIMULATEUR THERMIQUE ===\n');
fprintf('Matériau     : %s\n', mat.nom);
fprintf('Masse        : %.4f kg\n', m);
fprintf('Surface      : %.4f m²\n', A);
fprintf('Puissance    : %.1f W\n', P);
fprintf('T_ext        : %.1f °C\n', T_ext);
fprintf('h convection : %.1f W/m²·K\n', h);
fprintf('----------------------------\n');

% Température d'équilibre théorique (dT/dt = 0)
% P = h * A * (T_eq - T_ext)  →  T_eq = T_ext + P / (h * A)
T_eq = T_ext + P / (h * A);
fprintf('T équilibre théorique : %.2f °C\n', T_eq);

% Constante de temps thermique tau = m*Cp / (h*A)
tau = (m * mat.Cp) / (h * A);
fprintf('Constante de temps τ  : %.1f s (%.1f min)\n', tau, tau/60);

% Temps pour atteindre 90%% de l'équilibre ≈ 2.3 * tau
t_90 = 2.3 * tau;
fprintf('Temps 90%% équilibre   : %.1f s (%.1f min)\n', t_90, t_90/60);
fprintf('============================\n\n');

% ── 4. SIMULATION — EULER EXPLICITE ─────────────────────────

t = 0 : dt : t_fin;
N = length(t);
T = zeros(1, N);
T(1) = T0;

% Flux de chaleur perdu par convection et gain par puissance
for i = 1 : N-1
    Q_entree  = P;                           % W  (puissance constante)
    Q_sortie  = h * A * (T(i) - T_ext);     % W  (convection)
    dT        = (Q_entree - Q_sortie) / (m * mat.Cp);  % K/s
    T(i+1)    = T(i) + dT * dt;             % Euler explicite
end

% Solution analytique exacte pour vérification
% T(t) = T_eq + (T0 - T_eq) * exp(-t/tau)
T_analytique = T_eq + (T0 - T_eq) * exp(-t / tau);

% ── 5. VISUALISATION ────────────────────────────────────────

figure('Name', 'Simulateur Thermique', 'Position', [100 100 1100 700]);

% ── Courbe principale T(t) ──
subplot(2, 2, [1 2]);
hold on; grid on;

% Courbe numérique (Euler)
plot(t/60, T, 'Color', mat.couleur, 'LineWidth', 2.5, ...
    'DisplayName', sprintf('Euler — %s', mat.nom));

% Courbe analytique
plot(t/60, T_analytique, 'k--', 'LineWidth', 1.5, ...
    'DisplayName', 'Solution analytique');

% Ligne d'équilibre
yline(T_eq, 'r--', 'LineWidth', 1.2, ...
    'DisplayName', sprintf('T_{éq} = %.1f°C', T_eq));

% Ligne T_ext
yline(T_ext, 'b:', 'LineWidth', 1, ...
    'DisplayName', sprintf('T_{ext} = %.1f°C', T_ext));

xlabel('Temps (min)', 'FontSize', 11);
ylabel('Température (°C)', 'FontSize', 11);
title(sprintf('Évolution thermique — %s | P = %.0f W | T_{ext} = %.0f°C', ...
    mat.nom, P, T_ext), 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'southeast', 'FontSize', 10);
xlim([0 t_fin/60]);

% ── Erreur Euler vs analytique ──
subplot(2, 2, 3);
erreur = abs(T - T_analytique);
plot(t/60, erreur, 'r-', 'LineWidth', 1.5);
grid on;
xlabel('Temps (min)', 'FontSize', 10);
ylabel('|Erreur| (°C)', 'FontSize', 10);
title('Erreur Euler vs Analytique', 'FontSize', 11);
fprintf('Erreur max Euler : %.4f °C\n', max(erreur));

% ── Flux thermiques ──
subplot(2, 2, 4);
Q_conv = h * A * (T - T_ext);   % W perdu par convection
Q_stock = P - Q_conv;            % W stocké dans la plaque

plot(t/60, P * ones(1,N), 'g-', 'LineWidth', 2, 'DisplayName', 'P injectée');
hold on; grid on;
plot(t/60, Q_conv, 'r-', 'LineWidth', 2, 'DisplayName', 'Q convection');
plot(t/60, Q_stock, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Q stockée');
yline(0, 'k--', 'LineWidth', 0.8);
xlabel('Temps (min)', 'FontSize', 10);
ylabel('Puissance (W)', 'FontSize', 10);
title('Bilan thermique', 'FontSize', 11);
legend('Location', 'northeast', 'FontSize', 9);
xlim([0 t_fin/60]);

sgtitle('Simulateur Thermique — Plaque Métallique', ...
    'FontSize', 14, 'FontWeight', 'bold');

% ── 6. COMPARAISON DES MATÉRIAUX ────────────────────────────

figure('Name', 'Comparaison matériaux', 'Position', [200 200 900 500]);
hold on; grid on;

couleurs = {'b', 'r', 'Color', [0.9 0.5 0.2], [0.6 0.4 0.8]};

for idx = 1 : 4
    mat_i  = materiaux(idx);
    m_i    = mat_i.rho * V;
    tau_i  = (m_i * mat_i.Cp) / (h * A);
    T_eq_i = T_ext + P / (h * A);   % Même T_eq (indépendant du matériau)
    T_i    = T_eq_i + (T0 - T_eq_i) * exp(-t / tau_i);
    plot(t/60, T_i, 'LineWidth', 2, ...
        'Color', mat_i.couleur, ...
        'DisplayName', sprintf('%s (τ=%.0fs)', mat_i.nom, tau_i));
end

yline(T_eq, 'k--', 'LineWidth', 1.2, ...
    'DisplayName', sprintf('T_{éq} = %.1f°C', T_eq));

xlabel('Temps (min)', 'FontSize', 11);
ylabel('Température (°C)', 'FontSize', 11);
title(sprintf('Comparaison matériaux | P = %.0f W | T_{ext} = %.0f°C', P, T_ext), ...
    'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'southeast', 'FontSize', 10);
xlim([0 t_fin/60]);

fprintf('\n=== COMPARAISON MATÉRIAUX ===\n');
fprintf('%-12s | %-8s | %-8s | %-12s\n', 'Matériau', 'Masse(g)', 'τ (min)', 'T_éq (°C)');
fprintf('%s\n', repmat('-', 1, 50));
for idx = 1 : 4
    mat_i  = materiaux(idx);
    m_i    = mat_i.rho * V;
    tau_i  = (m_i * mat_i.Cp) / (h * A);
    T_eq_i = T_ext + P / (h * A);
    fprintf('%-12s | %-8.1f | %-8.2f | %-12.2f\n', ...
        mat_i.nom, m_i*1000, tau_i/60, T_eq_i);
end
