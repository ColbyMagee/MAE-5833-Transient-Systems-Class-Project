within ;
model AbsorptionCycle_001
  "Single-effect NH3-H2O absorption cycle - converted from EES script (states 1-8)"

  // ---------------------------------------------------------------------
  // FLUID: TILMedia_WaterAmmonia_nc2 (2 components: water, ammonia).
  // TILMedia's xi vector has nc-1 = 1 entry = mass fraction of the FIRST
  // component (water, by the record's name), so xi = 1 - X_NH3.
  // If results look inverted (X[3] ~ 0.05 instead of ~0.95), set
  // xiIsWater = false.
  //
  // PROPERTY CALLS (TILMedia 2024.1):
  //   TILMedia.VLEFluidFunctions.<name>(vleFluidType, inputs..., xi)
  //   -> the fluid record is the FIRST argument.
  // The VLEFluid_pT / VLEFluid_ph objects are NOT used: in this TILMedia
  // version they only accept fluids with nc = 1 (no variable concentration).
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
  parameter Modelica.Units.SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
  parameter Modelica.Units.SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
  parameter Real eta_p = 0.62 "Pump efficiency";

  parameter Modelica.Units.SI.AbsolutePressure P_gen = 1.6e6 "Generator pressure";
  parameter Modelica.Units.SI.AbsolutePressure P_abs = 400e3 "Absorber pressure";
  parameter Modelica.Units.SI.TemperatureDifference DT_cond = 4 "Condenser approach temperature";
  parameter Modelica.Units.SI.TemperatureDifference DT_evap = 3 "Evaporator approach temperature";
  parameter Modelica.Units.SI.MassFlowRate m_dot_r = 0.05 "Refrigerant mass flow rate";

  // -------------------- Solver start guesses --------------------
  parameter Real X_start[8] = {0.97, 0.97, 0.97, 0.97, 0.47, 0.47, 0.38, 0.38}
    "Start guesses for ammonia mass fractions (states 1-8)";

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
  Modelica.Units.SI.MassFlowRate m_dot_gen(start = 0.3) "Weak solution, generator -> absorber";
  Modelica.Units.SI.MassFlowRate m_dot_abs(start = 0.35) "Strong solution, absorber -> generator";

  Modelica.Units.SI.HeatFlowRate Q_dot_cond "Condenser heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_evap "Evaporator heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_gen(start = 8e4) "Generator heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_abs "Absorber heat duty";
  Modelica.Units.SI.Power W_dot_p "Pump power";

  Real COP "Coefficient of performance";

equation
  // ===================== Composition mapping =====================
  for i in 1:8 loop
    xi[i, 1] = if xiIsWater then 1 - X[i] else X[i];
  end for;

  // ===================== State 3 =====================
  // Saturated vapor leaving generator / entering condenser (Qu = 1 at P, T)
  T[3] = T_gen;
  P[3] = P_gen;
  Qu[3] = 1;
  T[3] = TILMedia.VLEFluidFunctions.dewTemperature_pxi(vleFluidType, P[3], xi[3, :])
    "Dew point at (P,T) fixes the vapor composition X[3]";
  h[3] = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(vleFluidType, P[3], xi[3, :]);

  // ===================== State 4 =====================
  // Liquid leaving condenser / entering valve 1
  P[4] = P[3];
  X[4] = X[3];
  T[4] = T_amb + DT_cond;
  h[4]  = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(vleFluidType, P[4], T[4], xi[4, :]);
  Qu[4] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[4], h[4], xi[4, :]);

  // ===================== State 1 =====================
  // Leaving valve 1 / entering evaporator (isenthalpic throttling)
  P[1] = P_abs;
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
  // Saturated liquid leaving absorber / entering pump (Qu = 0 at P, T)
  Qu[5] = 0;
  T[5] = T_abs;
  P[5] = P_abs;
  T[5] = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P[5], xi[5, :])
    "Bubble point at (P,T) fixes the liquid composition X[5]";
  h[5] = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P[5], xi[5, :]);
  rho5 = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, P[5], xi[5, :]);

  // ===================== State 6 =====================
  // Liquid leaving pump / entering generator
  X[6] = X[5];
  P[6] = P_gen;
  h[6] = h[5] + (P[6] - P[5]) / (rho5 * eta_p);
  T[6]  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P[6], h[6], xi[6, :]);
  Qu[6] = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P[6], h[6], xi[6, :]);

  // ===================== State 7 =====================
  // Saturated liquid leaving generator / entering valve 2 (Qu = 0 at P, T)
  Qu[7] = 0;
  P[7] = P_gen;
  T[7] = T_gen;
  T[7] = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P[7], xi[7, :])
    "Bubble point at (P,T) fixes the liquid composition X[7]";
  h[7] = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P[7], xi[7, :]);

  // ===================== State 8 =====================
  // Liquid leaving valve 2 / entering absorber (isenthalpic throttling)
  X[8] = X[7];
  P[8] = P_abs;
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

  annotation (Documentation(info="<html>
<p>Single-effect NH3-H2O absorption cycle (states 1-8) translated from EES,
using TILMedia_WaterAmmonia_nc2 via TILMedia.VLEFluidFunctions
(fluid record passed as the first argument).</p>
<p>Saturated states given (P, T, Q) in EES are solved with bubble/dew-point
functions: at fixed P, the bubble (Q=0) or dew (Q=1) temperature equation
determines the composition X, which is then used for enthalpy/density.</p>
<p>X is the ammonia mass fraction throughout; xi is the TILMedia composition
vector derived from it (see parameter xiIsWater). X_start holds the solver's
initial guesses for the compositions.</p>
</html>"), uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")));
end AbsorptionCycle_001;
