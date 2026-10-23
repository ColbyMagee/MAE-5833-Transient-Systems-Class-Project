within ;
model AbsorptionCycle_PressureTransient
  "Single-effect NH3-H2O absorption cycle - pressure start-up transient (states 1-8)"

  // ---------------------------------------------------------------------
  // TRANSIENT DESCRIPTION
  //  * At t = 0 the whole system sits at P_init = 800 kPa.
  //  * The high-side pressure (generator, condenser, pump outlet) rises toward
  //    P_gen_ss = 1600 kPa and the low-side pressure (evaporator, absorber,
  //    valve outlets) falls toward P_abs_ss = 400 kPa, each as a first-order
  //    approach with time constant tau_P:
  //        tau_P * der(P_high) = P_gen_ss - P_high
  //        tau_P * der(P_low)  = P_abs_ss - P_low
  //  * The weak solution (generator, state 7) and the strong solution
  //    (absorber, state 5) keep their steady-state compositions, so their
  //    temperatures follow their bubble-point (saturation) temperatures:
  //        T_gen(t) = T_bubble(P_high(t), X_weak)
  //        T_abs(t) = T_bubble(P_low(t),  X_strong)
  //    X_weak and X_strong are computed at initialization so that
  //    T_gen -> 90 C and T_abs -> 32 C when the pressures reach steady state.
  //  * Everything else is solved at every instant with the same equations as
  //    the steady model (refrigerant flow fixed at m_dot_r).
  //
  // FLUID: TILMedia_WaterAmmonia_nc2, xi[1] = water mass fraction (xiIsWater).
  // Property calls: TILMedia.VLEFluidFunctions.<name>(vleFluidType, inputs..., xi)
  // ---------------------------------------------------------------------

  replaceable parameter TILMedia.VLEFluidTypes.TILMedia_WaterAmmonia_nc2 vleFluidType
    constrainedby TILMedia.VLEFluidTypes.BaseVLEFluid
    "NH3-H2O working fluid"
    annotation (choicesAllMatching=true);

  parameter Boolean xiIsWater = true
    "true: TILMedia xi[1] is the water mass fraction (xi = 1 - X_NH3)";

  // -------------------- Inputs / Parameters --------------------
  parameter Modelica.Units.SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
  parameter Modelica.Units.SI.Temperature T_C   = 273.15 + 5  "Evaporator temperature";
  parameter Real eta_p = 0.62 "Pump efficiency";
  parameter Modelica.Units.SI.TemperatureDifference DT_cond = 4 "Condenser approach temperature";
  parameter Modelica.Units.SI.TemperatureDifference DT_evap = 3 "Evaporator approach temperature";
  parameter Modelica.Units.SI.MassFlowRate m_dot_r = 0.05 "Refrigerant mass flow rate";

  // -------------------- Steady-state (target) values --------------------
  parameter Modelica.Units.SI.AbsolutePressure P_gen_ss = 1.6e6 "Steady-state generator (high-side) pressure";
  parameter Modelica.Units.SI.AbsolutePressure P_abs_ss = 400e3 "Steady-state absorber (low-side) pressure";
  parameter Modelica.Units.SI.Temperature T_gen_ss = 273.15 + 90 "Steady-state generator temperature";
  parameter Modelica.Units.SI.Temperature T_abs_ss = 273.15 + 32 "Steady-state absorber temperature";

  // -------------------- Transient settings --------------------
  parameter Modelica.Units.SI.AbsolutePressure P_init = 800e3 "Uniform system pressure at t = 0";
  parameter Modelica.Units.SI.Time tau_P = 60 "Time constant of the pressure approach";

  // -------------------- Solution compositions (computed at initialization) --------------------
  parameter Modelica.Units.SI.MassFraction X_weak(fixed = false, start = 0.45)
    "Weak-solution ammonia fraction (generator), gives T_gen_ss at P_gen_ss";
  parameter Modelica.Units.SI.MassFraction X_strong(fixed = false, start = 0.50)
    "Strong-solution ammonia fraction (absorber), gives T_abs_ss at P_abs_ss";

  // -------------------- Solver start guesses --------------------
  parameter Real X_start[8] = {0.97, 0.97, 0.97, 0.97, 0.50, 0.50, 0.45, 0.45}
    "Start guesses for ammonia mass fractions (states 1-8)";

  // -------------------- Transient pressures and temperatures --------------------
  Modelica.Units.SI.AbsolutePressure P_high(start = P_init) "High-side pressure (state)";
  Modelica.Units.SI.AbsolutePressure P_low(start = P_init) "Low-side pressure (state)";
  Modelica.Units.SI.Temperature T_gen(start = T_gen_ss) "Generator temperature";
  Modelica.Units.SI.Temperature T_abs(start = T_abs_ss) "Absorber temperature";

  // -------------------- State arrays (states 1-8) --------------------
  Modelica.Units.SI.Temperature T[8](each start = 300) "State temperatures";
  Modelica.Units.SI.AbsolutePressure P[8](each start = 1e6) "State pressures";
  Modelica.Units.SI.SpecificEnthalpy h[8](each start = 3e5) "State specific enthalpies";
  Real X[8](start = X_start, each min = 0, each max = 1) "State AMMONIA mass fractions";
  Real xi[8, 1](start = if xiIsWater then [1 .- X_start] else [X_start],
                each min = 0, each max = 1) "TILMedia composition vectors (derived from X)";
  Real Qu[8] "State vapor qualities";

  Modelica.Units.SI.Density rho5 "Density at state 5 (saturated liquid, absorber exit)";

  // -------------------- Flow / energy quantities --------------------
  Modelica.Units.SI.MassFlowRate m_dot_gen(start = 0.5) "Weak solution, generator -> absorber";
  Modelica.Units.SI.MassFlowRate m_dot_abs(start = 0.55) "Strong solution, absorber -> generator";

  Modelica.Units.SI.HeatFlowRate Q_dot_cond "Condenser heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_evap "Evaporator heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_gen(start = 2e5) "Generator heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_abs "Absorber heat duty";
  Modelica.Units.SI.Power W_dot_p "Pump power";

  Real COP "Coefficient of performance";

  // -------------------- Convenience outputs for plotting --------------------
  Real T_degC[8] = T .- 273.15 "State temperatures [degC]";
  Real P_kPa[8] = P ./ 1e3 "State pressures [kPa]";
  Real h_kJkg[8] = h ./ 1e3 "State specific enthalpies [kJ/kg]";
  Real T_gen_degC = T_gen - 273.15 "Generator temperature [degC]";
  Real T_abs_degC = T_abs - 273.15 "Absorber temperature [degC]";
  Real P_high_kPa = P_high/1e3 "High-side pressure [kPa]";
  Real P_low_kPa = P_low/1e3 "Low-side pressure [kPa]";

initial equation
  // Whole system starts at P_init
  P_high = P_init;
  P_low = P_init;

  // Solution compositions that give the steady-state temperatures at steady-state pressures
  T_gen_ss = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P_gen_ss,
    {if xiIsWater then 1 - X_weak else X_weak});
  T_abs_ss = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P_abs_ss,
    {if xiIsWater then 1 - X_strong else X_strong});

equation
  assert(X_strong > X_weak, "Strong solution must be richer in ammonia than the weak solution");

  // ===================== Pressure transient =====================
  tau_P * der(P_high) = P_gen_ss - P_high;
  tau_P * der(P_low)  = P_abs_ss - P_low;

  // ===================== Composition mapping =====================
  for i in 1:8 loop
    xi[i, 1] = if xiIsWater then 1 - X[i] else X[i];
  end for;

  // ===================== State 7 =====================
  // Saturated weak solution leaving generator: fixed composition, so its
  // temperature follows the bubble point at the current high-side pressure
  Qu[7] = 0;
  P[7] = P_high;
  X[7] = X_weak;
  T[7] = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P[7], xi[7, :]);
  h[7] = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P[7], xi[7, :]);
  T_gen = T[7];

  // ===================== State 3 =====================
  // Saturated vapor leaving generator at T_gen: dew point fixes its composition
  T[3] = T_gen;
  P[3] = P_high;
  Qu[3] = 1;
  T[3] = TILMedia.VLEFluidFunctions.dewTemperature_pxi(vleFluidType, P[3], xi[3, :])
    "Dew point at (P,T) fixes the vapor composition X[3]";
  h[3] = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(vleFluidType, P[3], xi[3, :]);

  // ===================== State 4 =====================
  // Leaving condenser / entering valve 1
  P[4] = P[3];
  X[4] = X[3];
  T[4] = T_amb + DT_cond;
  h[4]  = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(vleFluidType, P[4], T[4], xi[4, :]);
  Qu[4] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[4], h[4], xi[4, :]);

  // ===================== State 1 =====================
  // Leaving valve 1 / entering evaporator (isenthalpic throttling)
  P[1] = P_low;
  X[1] = X[4];
  h[1] = h[4];
  T[1]  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P[1], h[1], xi[1, :]);
  Qu[1] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[1], h[1], xi[1, :]);

  // ===================== State 2 =====================
  // Leaving evaporator / entering absorber
  P[2] = P[1];
  X[2] = X[1];
  T[2] = T_C - DT_evap;
  h[2]  = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(vleFluidType, P[2], T[2], xi[2, :]);
  Qu[2] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[2], h[2], xi[2, :]);

  // ===================== State 5 =====================
  // Saturated strong solution leaving absorber: fixed composition, so its
  // temperature follows the bubble point at the current low-side pressure
  Qu[5] = 0;
  P[5] = P_low;
  X[5] = X_strong;
  T[5] = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P[5], xi[5, :]);
  h[5] = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P[5], xi[5, :]);
  rho5 = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, P[5], xi[5, :]);
  T_abs = T[5];

  // ===================== State 6 =====================
  // Liquid leaving pump / entering generator
  X[6] = X[5];
  P[6] = P_high;
  h[6] = h[5] + (P[6] - P[5]) / (rho5 * eta_p);
  T[6]  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P[6], h[6], xi[6, :]);
  Qu[6] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[6], h[6], xi[6, :]);

  // ===================== State 8 =====================
  // Liquid leaving valve 2 / entering absorber (isenthalpic throttling)
  X[8] = X[7];
  P[8] = P_low;
  h[8] = h[7];
  T[8]  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P[8], h[8], xi[8, :]);
  Qu[8] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[8], h[8], xi[8, :]);

  // ===================== Condenser / evaporator energy balances =====================
  Q_dot_cond = m_dot_r * (h[3] - h[4]);
  Q_dot_evap = m_dot_r * (h[2] - h[1]);

  // ===================== Absorber mass balances =====================
  m_dot_r * X[2] + m_dot_gen * X[8] = m_dot_abs * X[5];
  m_dot_r + m_dot_gen = m_dot_abs;

  // ===================== Absorber, pump, generator energy balances =====================
  m_dot_r * h[2] + m_dot_gen * h[8] = Q_dot_abs + m_dot_abs * h[5];   // Absorber
  W_dot_p = m_dot_abs * (h[6] - h[5]);                                // Pump
  m_dot_abs * h[6] + Q_dot_gen = m_dot_r * h[3] + m_dot_gen * h[7];   // Generator

  // ===================== Performance =====================
  COP = Q_dot_evap / Q_dot_gen;

  annotation (
    experiment(StopTime = 300, Interval = 0.5, Tolerance = 1e-6),
    Documentation(info="<html>
<p>Start-up transient of the single-effect NH3-H2O absorption cycle
(states 1-8, same equations as AbsorptionCycle_001).</p>
<p><b>Transient:</b> the system starts at a uniform pressure P_init (800 kPa).
The high-side pressure rises to P_gen_ss and the low-side pressure falls to
P_abs_ss with a first-order time constant tau_P.</p>
<p><b>Temperatures:</b> the weak and strong solutions keep their steady-state
compositions (X_weak, X_strong, computed at initialization), so the generator
and absorber temperatures follow their bubble-point temperatures at the current
pressure and reach T_gen_ss and T_abs_ss at steady state.</p>
<p><b>Suggested plots:</b> P_high_kPa, P_low_kPa, T_gen_degC, T_abs_degC,
Q_dot_gen, Q_dot_evap, COP, X[3].</p>
</html>"),
    uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")));
end AbsorptionCycle_PressureTransient;
