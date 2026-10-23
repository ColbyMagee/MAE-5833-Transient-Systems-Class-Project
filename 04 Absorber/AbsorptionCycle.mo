within ;
model AbsorptionCycle
  "Single-effect NH3-H2O absorption cycle - converted from EES script (states 1-8)"

  // ---------------------------------------------------------------------
  // NOTE ON TILMedia FUNCTION NAMES
  // TILMedia's exact function names/signatures for VLE equilibrium
  // properties (bubble/dew composition, quality-from-(p,T,x), etc.) differ
  // between TILMedia 3.x / 4.x installations. The calls below use the
  // TILMedia.VLEFluidObjectFunctions naming convention (vleFluidType as
  // first argument) that's typical for TILMedia.VLEFluidTypes-based
  // ammonia-water objects. Check these against your installed library
  // (Modelica class browser -> TILMedia.VLEFluidObjectFunctions) and
  // adjust names/argument order if they don't match - the state/energy-
  // balance structure below is where the physics lives and shouldn't
  // need to change.
  // ---------------------------------------------------------------------

  replaceable package Medium = TILMedia.VLEFluidTypes.TILMedia_NH3_H2O
    "NH3-H2O working fluid (adjust to your TILMedia media class name)";

  Medium.VLEFluidType vleFluidType = Medium.VLEFluidType()
    "TILMedia fluid type record, passed to all property functions";

  // -------------------- Inputs / Parameters --------------------
  parameter Modelica.Units.SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
  parameter Modelica.Units.SI.Temperature T_C   = 273.15 + 5  "Evaporator temperature";
  parameter Modelica.Units.SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
  parameter Modelica.Units.SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
  parameter Real eta_p = 0.62 "Pump efficiency";

  parameter Modelica.Units.SI.AbsolutePressure P_gen = 1.6e6 "Generator pressure (Pa)";
  parameter Modelica.Units.SI.AbsolutePressure P_abs = 400e3 "Absorber pressure (Pa)";
  parameter Modelica.Units.SI.TemperatureDifference DT_cond = 4 "Condenser approach temp";
  parameter Modelica.Units.SI.TemperatureDifference DT_evap = 3 "Evaporator approach temp";
  parameter Modelica.Units.SI.MassFlowRate m_dot_r = 0.05 "Refrigerant mass flow rate";

  // -------------------- State arrays (states 1-8) --------------------
  Modelica.Units.SI.Temperature T[8](start = fill(300, 8)) "State temperatures";
  Modelica.Units.SI.AbsolutePressure P[8] "State pressures";
  Modelica.Units.SI.SpecificEnthalpy h[8] "State specific enthalpies";
  Real X[8](each start = 0.5) "State ammonia mass fractions";
  Real Qu[8](each start = 0.5) "State vapor qualities (defined only where used)";

  Modelica.Units.SI.Density rho5 "Density at state 5 (saturated liquid, absorber exit)";

  // -------------------- Flow / energy quantities --------------------
  Modelica.Units.SI.MassFlowRate m_dot_gen "Weak-solution mass flow (absorber -> generator branch)";
  Modelica.Units.SI.MassFlowRate m_dot_abs "Strong-solution mass flow leaving absorber";

  Modelica.Units.SI.HeatFlowRate Q_dot_cond "Condenser heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_evap "Evaporator heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_gen  "Generator heat duty";
  Modelica.Units.SI.HeatFlowRate Q_dot_abs  "Absorber heat duty";
  Modelica.Units.SI.Power W_dot_p "Pump power";

  Real COP "Coefficient of performance";

equation
  // ===================== State 3 =====================
  // Vapor leaving generator / entering condenser
  T[3] = T_gen;
  P[3] = P_gen;
  Qu[3] = 1;
  X[3] = TILMedia.VLEFluidObjectFunctions.massFraction_pTq(vleFluidType, P[3], T[3], Qu[3]);
  h[3] = TILMedia.VLEFluidObjectFunctions.specificEnthalpy_pTxi(vleFluidType, P[3], T[3], {X[3]});

  // ===================== State 4 =====================
  // Liquid leaving condenser / entering valve 1
  P[4] = P[3];
  X[4] = X[3];
  T[4] = T_amb + DT_cond;
  h[4] = TILMedia.VLEFluidObjectFunctions.specificEnthalpy_pTxi(vleFluidType, P[4], T[4], {X[4]});

  // ===================== State 1 =====================
  // Leaving valve 1 / entering evaporator (isenthalpic throttling)
  P[1] = P_abs;
  X[1] = X[4];
  h[1] = h[4];
  T[1]  = TILMedia.VLEFluidObjectFunctions.temperature_phxi(vleFluidType, P[1], h[1], {X[1]});
  Qu[1] = TILMedia.VLEFluidObjectFunctions.vaporQuality_phxi(vleFluidType, P[1], h[1], {X[1]});

  // ===================== State 2 =====================
  // Leaving evaporator / entering absorber
  P[2] = P[1];
  X[2] = X[1];
  T[2] = T_C - DT_evap;
  h[2]  = TILMedia.VLEFluidObjectFunctions.specificEnthalpy_pTxi(vleFluidType, P[2], T[2], {X[2]});
  Qu[2] = TILMedia.VLEFluidObjectFunctions.vaporQuality_pTxi(vleFluidType, P[2], T[2], {X[2]});

  // ===================== State 5 =====================
  // Liquid leaving absorber / entering pump (saturated liquid)
  Qu[5] = 0;
  T[5] = T_abs;
  P[5] = P_abs;
  h[5]  = TILMedia.VLEFluidObjectFunctions.specificEnthalpy_pTq(vleFluidType, P[5], T[5], Qu[5]);
  X[5]  = TILMedia.VLEFluidObjectFunctions.massFraction_pTq(vleFluidType, P[5], T[5], Qu[5]);
  rho5  = TILMedia.VLEFluidObjectFunctions.density_pTxi(vleFluidType, P[5], T[5], {X[5]});

  // ===================== State 6 =====================
  // Liquid leaving pump / entering generator
  X[6] = X[5];
  P[6] = P_gen;
  h[6] = h[5] + (P[6] - P[5]) / (rho5 * eta_p);

  // ===================== State 7 =====================
  // Liquid leaving generator / entering valve 2 (saturated liquid)
  Qu[7] = 0;
  P[7] = P_gen;
  T[7] = T_gen;
  h[7] = TILMedia.VLEFluidObjectFunctions.specificEnthalpy_pTq(vleFluidType, P[7], T[7], Qu[7]);
  X[7] = TILMedia.VLEFluidObjectFunctions.massFraction_pTq(vleFluidType, P[7], T[7], Qu[7]);

  // ===================== State 8 =====================
  // Liquid leaving valve 2 / entering absorber (isenthalpic throttling)
  X[8] = X[7];
  P[8] = P_abs;
  h[8] = h[7];
  T[8] = TILMedia.VLEFluidObjectFunctions.temperature_phxi(vleFluidType, P[8], h[8], {X[8]});

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
    Documentation(info="<html>
<p>Direct translation of an EES single-effect NH3-H2O absorption cycle model
(states 1 through 8) into Modelica, using TILMedia VLE fluid property
function calls in place of EES's built-in NH3H2O property routines.</p>
<p><b>Units:</b> EES inputs were given in Celsius and kPa; this model
converts them to SI (Kelvin, Pa) at the parameter declarations so all
internal equations are pure SI, which is standard Modelica practice.</p>
<p><b>Unknowns not fully constrained here:</b> as in the original EES code,
Q_dot_abs, Q_dot_gen, m_dot_gen and m_dot_abs are solved implicitly from the
mass/energy balance equations together - there's no need to reorder them,
Modelica's equation-based solver handles the simultaneous system (EES does
the same). If you get a structural singularity, it's most likely because
one of these four is still underdetermined for your particular boundary
conditions (e.g. if m_dot_gen/m_dot_abs also depend on an externally fixed
circulation ratio in your full model).</p>
<p><b>To verify against your TILMedia install:</b> the six
<code>TILMedia.VLEFluidObjectFunctions.*</code> calls (massFraction_pTq,
specificEnthalpy_pTxi, specificEnthalpy_pTq, temperature_phxi,
vaporQuality_phxi, vaporQuality_pTxi, density_pTxi) - open
TILMedia.VLEFluidObjectFunctions in the Modelica class browser and confirm
these exact names/argument orders exist for your TILMedia version and your
NH3-H2O medium class; rename as needed.</p>
</html>"));
end AbsorptionCycle;
