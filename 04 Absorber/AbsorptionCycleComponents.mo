within ;
package AbsorptionCycleComponents
  "Component-based steady-state NH3-H2O absorption cycle with diagram graphics"
  extends Modelica.Icons.Package;

  // =====================================================================
  //  INTERFACES
  // =====================================================================
  package Interfaces "Connectors and base classes"
    extends Modelica.Icons.InterfacesPackage;

    connector FluidPortIn
      "Fluid inlet: state arriving at a component (filled circle)"
      input Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate";
      input Modelica.Units.SI.AbsolutePressure p "Pressure";
      input Modelica.Units.SI.SpecificEnthalpy h "Specific enthalpy";
      input Modelica.Units.SI.MassFraction X "Ammonia mass fraction";
      input Modelica.Units.SI.Temperature T "Temperature";
      annotation (
        Icon(graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid)}),
        Diagram(graphics={Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid), Text(
              extent={{-150,110},{150,50}},
              textString="%name")}));
    end FluidPortIn;

    connector FluidPortOut
      "Fluid outlet: state leaving a component (hollow circle)"
      output Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate";
      output Modelica.Units.SI.AbsolutePressure p "Pressure";
      output Modelica.Units.SI.SpecificEnthalpy h "Specific enthalpy";
      output Modelica.Units.SI.MassFraction X "Ammonia mass fraction";
      output Modelica.Units.SI.Temperature T "Temperature";
      annotation (
        Icon(graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid), Ellipse(
              extent={{-60,60},{60,-60}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}),
        Diagram(graphics={Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid), Ellipse(
              extent={{-24,24},{24,-24}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid), Text(
              extent={{-150,110},{150,50}},
              textString="%name")}));
    end FluidPortOut;

    partial model PartialComponent "Fluid parameters shared by all components"
      replaceable parameter TILMedia.VLEFluidTypes.TILMedia_WaterAmmonia_nc2 vleFluidType
        constrainedby TILMedia.VLEFluidTypes.BaseVLEFluid
        "NH3-H2O working fluid"
        annotation (choicesAllMatching=true, Dialog(tab="Fluid"));
      parameter Boolean xiIsWater = true
        "true: TILMedia xi[1] is the water mass fraction (xi = 1 - X_NH3)"
        annotation (Dialog(tab="Fluid"));
    end PartialComponent;
  end Interfaces;

  // =====================================================================
  //  FUNCTIONS
  // =====================================================================
  package Functions "Helper functions"
    extends Modelica.Icons.FunctionsPackage;

    function xiFromX "TILMedia composition vector from ammonia mass fraction"
      extends Modelica.Icons.Function;
      input Real X "Ammonia mass fraction";
      input Boolean xiIsWater "true: xi[1] is the water mass fraction";
      output Real xi[1] "TILMedia composition vector";
    algorithm
      xi := {if xiIsWater then 1 - X else X};
      annotation (Inline=true);
    end xiFromX;
  end Functions;

  // =====================================================================
  //  COMPONENTS
  // =====================================================================
  package Components "Cycle components"
    extends Modelica.Icons.Package;

    // -------------------------------------------------------------------
    model Generator
      "Generator (desorber): saturated vapor and saturated weak solution leave at T_gen"
      extends Interfaces.PartialComponent;

      parameter Modelica.Units.SI.Temperature T_gen = 273.15 + 90
        "Generator temperature";
      parameter Modelica.Units.SI.MassFlowRate m_dot_r = 0.05
        "Refrigerant vapor flow (design specification)";
      parameter Modelica.Units.SI.MassFraction X_vap_start = 0.97
        "Start guess, vapor ammonia fraction"
        annotation (Dialog(tab="Initialization"));
      parameter Modelica.Units.SI.MassFraction X_liq_start = 0.45
        "Start guess, weak-solution ammonia fraction"
        annotation (Dialog(tab="Initialization"));

      Interfaces.FluidPortIn inlet "Strong solution from pump (state 6)"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));
      Interfaces.FluidPortOut vapor(
        X(start=X_vap_start),
        T(start=T_gen),
        h(start=1.5e6)) "Refrigerant vapor to condenser (state 3)"
        annotation (Placement(transformation(extent={{-110,30},{-90,50}})));
      Interfaces.FluidPortOut liquid(
        X(start=X_liq_start),
        T(start=T_gen),
        h(start=3e5),
        m_flow(start=0.5)) "Weak solution to solution valve (state 7)"
        annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));

      Modelica.Units.SI.HeatFlowRate Q_flow "Heat input to the generator";

    protected
      Real xi_vap[1] = Functions.xiFromX(vapor.X, xiIsWater);
      Real xi_liq[1] = Functions.xiFromX(liquid.X, xiIsWater);

    equation
      // Pressure is set by the pump (inlet)
      vapor.p = inlet.p;
      liquid.p = inlet.p;

      // Both streams leave at the generator temperature
      vapor.T = T_gen;
      liquid.T = T_gen;

      // Saturated vapor (Q = 1): dew point at (p, T) fixes the vapor composition
      vapor.T = TILMedia.VLEFluidFunctions.dewTemperature_pxi(vleFluidType, vapor.p, xi_vap);
      vapor.h = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(vleFluidType, vapor.p, xi_vap);

      // Saturated liquid (Q = 0): bubble point at (p, T) fixes the weak-solution composition
      liquid.T = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, liquid.p, xi_liq);
      liquid.h = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, liquid.p, xi_liq);

      // Mass balances: vapor flow is the design spec; the ammonia balance sets the
      // weak-solution flow. The total mass balance (inlet = vapor + liquid) then
      // holds automatically around the closed loop, so it is not written twice.
      vapor.m_flow = m_dot_r;
      inlet.m_flow*inlet.X = vapor.m_flow*vapor.X + liquid.m_flow*liquid.X;

      // Energy balance
      inlet.m_flow*inlet.h + Q_flow = vapor.m_flow*vapor.h + liquid.m_flow*liquid.h;

      annotation (Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
            Rectangle(
              extent={{-100,70},{100,-70}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={255,214,185},
              fillPattern=FillPattern.Solid,
              radius=15),
            Rectangle(
              extent={{-92,-8},{92,-62}},
              lineColor={153,204,255},
              pattern=LinePattern.None,
              fillColor={153,204,255},
              fillPattern=FillPattern.Solid,
              radius=10),
            Text(
              extent={{-90,58},{90,20}},
              textString="GENERATOR",
              textColor={0,0,0}),
            Text(
              extent={{-90,-14},{90,-56}},
              textString=DynamicSelect("Q_gen", String(Q_flow/1000, format=".1f") + " kW"),
              textColor={0,0,0}),
            Polygon(
              points={{-8,100},{8,100},{8,88},{20,88},{0,72},{-20,88},{-8,88},{-8,100}},
              lineColor={238,46,47},
              fillColor={238,46,47},
              fillPattern=FillPattern.Solid),
            Line(
              points={{0,-70},{0,-90}},
              color={0,127,255},
              thickness=0.5),
            Text(
              extent={{-150,140},{150,106}},
              textString="%name",
              textColor={0,0,255})}),
        Documentation(info="<html>
<p>Saturated vapor (state 3) and saturated weak solution (state 7) leave at
T_gen and the pump pressure. Heat input Q_flow follows from the energy balance.</p>
</html>"));
    end Generator;

    // -------------------------------------------------------------------
    model Condenser "Condenser: refrigerant leaves as liquid at T_out"
      extends Interfaces.PartialComponent;

      parameter Modelica.Units.SI.Temperature T_out = 273.15 + 29
        "Outlet temperature (ambient + approach)";

      Interfaces.FluidPortIn inlet "Vapor from generator (state 3)"
        annotation (Placement(transformation(extent={{90,30},{110,50}})));
      Interfaces.FluidPortOut outlet(T(start=T_out), h(start=4e5))
        "Liquid to refrigerant valve (state 4)"
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));

      Modelica.Units.SI.HeatFlowRate Q_flow "Heat rejected by the condenser";
      Real Qu_out "Outlet vapor quality";

    protected
      Real xi_out[1] = Functions.xiFromX(outlet.X, xiIsWater);

    equation
      outlet.m_flow = inlet.m_flow;
      outlet.p = inlet.p;
      outlet.X = inlet.X;
      outlet.T = T_out;
      outlet.h = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(vleFluidType, outlet.p, outlet.T, xi_out);
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, outlet.p, outlet.h, xi_out);
      Q_flow = inlet.m_flow*(inlet.h - outlet.h);

      annotation (Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
            Rectangle(
              extent={{-100,70},{100,-70}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={204,229,255},
              fillPattern=FillPattern.Solid,
              radius=15),
            Text(
              extent={{-90,50},{90,10}},
              textString="CONDENSER",
              textColor={0,0,0}),
            Text(
              extent={{-90,-10},{90,-50}},
              textString=DynamicSelect("Q_cond", String(Q_flow/1000, format=".1f") + " kW"),
              textColor={0,0,0}),
            Polygon(
              points={{-8,72},{8,72},{8,86},{20,86},{0,100},{-20,86},{-8,86},{-8,72}},
              lineColor={0,0,255},
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,140},{150,106}},
              textString="%name",
              textColor={0,0,255})}),
        Documentation(info="<html>
<p>Refrigerant (state 3) is condensed and cooled to T_out at constant pressure
(state 4). Q_flow is the heat rejected.</p>
</html>"));
    end Condenser;

    // -------------------------------------------------------------------
    model ExpansionValve "Isenthalpic throttling valve (flow from top to bottom)"
      extends Interfaces.PartialComponent;

      parameter Modelica.Units.SI.AbsolutePressure p_out = 400e3
        "Outlet (low-side) pressure";

      Interfaces.FluidPortIn inlet "High-pressure inlet"
        annotation (Placement(transformation(extent={{-10,90},{10,110}})));
      Interfaces.FluidPortOut outlet(T(start=300), h(start=3e5))
        "Low-pressure outlet"
        annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));

      Real Qu_out "Outlet vapor quality (flash fraction)";

    protected
      Real xi_out[1] = Functions.xiFromX(outlet.X, xiIsWater);

    equation
      outlet.m_flow = inlet.m_flow;
      outlet.X = inlet.X;
      outlet.p = p_out;
      outlet.h = inlet.h;
      outlet.T = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, outlet.p, outlet.h, xi_out);
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, outlet.p, outlet.h, xi_out);

      annotation (Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
            Polygon(
              points={{-50,90},{50,90},{0,0},{-50,90}},
              lineColor={0,0,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{-50,-90},{50,-90},{0,0},{-50,-90}},
              lineColor={0,0,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{60,40},{250,-40}},
              textString="%name",
              textColor={0,0,255},
              horizontalAlignment=TextAlignment.Left)}),
        Documentation(info="<html>
<p>Isenthalpic expansion to p_out: h_out = h_in, composition unchanged.</p>
</html>"));
    end ExpansionValve;

    // -------------------------------------------------------------------
    model Evaporator "Evaporator: refrigerant leaves at T_out"
      extends Interfaces.PartialComponent;

      parameter Modelica.Units.SI.Temperature T_out = 273.15 + 2
        "Outlet temperature (evaporator temperature - approach)";

      Interfaces.FluidPortIn inlet "Two-phase refrigerant from valve (state 1)"
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
      Interfaces.FluidPortOut outlet(T(start=T_out), h(start=1.3e6))
        "Refrigerant to absorber (state 2)"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));

      Modelica.Units.SI.HeatFlowRate Q_flow "Cooling capacity (heat absorbed)";
      Real Qu_out "Outlet vapor quality";

    protected
      Real xi_out[1] = Functions.xiFromX(outlet.X, xiIsWater);

    equation
      outlet.m_flow = inlet.m_flow;
      outlet.p = inlet.p;
      outlet.X = inlet.X;
      outlet.T = T_out;
      outlet.h = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(vleFluidType, outlet.p, outlet.T, xi_out);
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, outlet.p, outlet.h, xi_out);
      Q_flow = inlet.m_flow*(outlet.h - inlet.h);

      annotation (Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
            Rectangle(
              extent={{-100,70},{100,-70}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={220,240,255},
              fillPattern=FillPattern.Solid,
              radius=15),
            Text(
              extent={{-90,50},{90,10}},
              textString="EVAPORATOR",
              textColor={0,0,0}),
            Text(
              extent={{-90,-10},{90,-50}},
              textString=DynamicSelect("Q_evap", String(Q_flow/1000, format=".1f") + " kW"),
              textColor={0,0,0}),
            Polygon(
              points={{-8,-100},{8,-100},{8,-86},{20,-86},{0,-72},{-20,-86},{-8,-86},{-8,-100}},
              lineColor={238,46,47},
              fillColor={238,46,47},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,110},{150,76}},
              textString="%name",
              textColor={0,0,255})}),
        Documentation(info="<html>
<p>Refrigerant from the valve (state 1) is evaporated at constant pressure to
T_out (state 2). Q_flow is the cooling capacity.</p>
</html>"));
    end Evaporator;

    // -------------------------------------------------------------------
    model Absorber
      "Absorber: vapor and weak solution in, saturated strong solution out at T_abs"
      extends Interfaces.PartialComponent;

      parameter Modelica.Units.SI.Temperature T_abs = 273.15 + 32
        "Absorber temperature";
      parameter Modelica.Units.SI.MassFraction X_start = 0.5
        "Start guess, strong-solution ammonia fraction"
        annotation (Dialog(tab="Initialization"));

      Interfaces.FluidPortIn vapor_in "Refrigerant from evaporator (state 2)"
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
      Interfaces.FluidPortIn liquid_in "Weak solution from solution valve (state 8)"
        annotation (Placement(transformation(extent={{-10,90},{10,110}})));
      Interfaces.FluidPortOut outlet(
        X(start=X_start),
        T(start=T_abs),
        h(start=1e5),
        m_flow(start=0.6)) "Strong solution to pump (state 5)"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));

      Modelica.Units.SI.HeatFlowRate Q_flow "Heat rejected by the absorber";

    protected
      Real xi_out[1] = Functions.xiFromX(outlet.X, xiIsWater);

    equation
      // Pressure is the low-side pressure of the incoming vapor
      outlet.p = vapor_in.p;

      // Saturated liquid (Q = 0) at T_abs: bubble point fixes the strong-solution composition
      outlet.T = T_abs;
      outlet.T = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, outlet.p, xi_out);
      outlet.h = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, outlet.p, xi_out);

      // Total mass balance (the ammonia balance is closed in the generator)
      outlet.m_flow = vapor_in.m_flow + liquid_in.m_flow;

      // Energy balance
      vapor_in.m_flow*vapor_in.h + liquid_in.m_flow*liquid_in.h = Q_flow + outlet.m_flow*outlet.h;

      annotation (Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
            Rectangle(
              extent={{-100,70},{100,-70}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={230,220,255},
              fillPattern=FillPattern.Solid,
              radius=15),
            Rectangle(
              extent={{-92,-8},{92,-62}},
              lineColor={153,204,255},
              pattern=LinePattern.None,
              fillColor={153,204,255},
              fillPattern=FillPattern.Solid,
              radius=10),
            Text(
              extent={{-90,58},{90,20}},
              textString="ABSORBER",
              textColor={0,0,0}),
            Text(
              extent={{-90,-14},{90,-56}},
              textString=DynamicSelect("Q_abs", String(Q_flow/1000, format=".1f") + " kW"),
              textColor={0,0,0}),
            Line(
              points={{0,70},{0,90}},
              color={0,127,255},
              thickness=0.5),
            Polygon(
              points={{-8,-72},{8,-72},{8,-86},{20,-86},{0,-100},{-20,-86},{-8,-86},{-8,-72}},
              lineColor={0,0,255},
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,-106},{150,-140}},
              textString="%name",
              textColor={0,0,255})}),
        Documentation(info="<html>
<p>Refrigerant vapor (state 2) is absorbed into the weak solution (state 8);
strong solution leaves as saturated liquid at T_abs (state 5). Q_flow is the
heat of absorption rejected.</p>
</html>"));
    end Absorber;

    // -------------------------------------------------------------------
    model SolutionPump "Solution pump (flow from bottom to top)"
      extends Interfaces.PartialComponent;

      parameter Modelica.Units.SI.AbsolutePressure p_out = 1.6e6
        "Outlet (high-side) pressure";
      parameter Real eta = 0.62 "Pump efficiency";

      Interfaces.FluidPortIn inlet "Strong solution from absorber (state 5)"
        annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
      Interfaces.FluidPortOut outlet(T(start=305), h(start=1e5))
        "Strong solution to generator (state 6)"
        annotation (Placement(transformation(extent={{-10,90},{10,110}})));

      Modelica.Units.SI.Power W_flow "Pump power";
      Modelica.Units.SI.Density rho_in "Inlet density (saturated liquid assumed)";
      Real Qu_out "Outlet vapor quality";

    protected
      Real xi[1] = Functions.xiFromX(inlet.X, xiIsWater);

    equation
      outlet.m_flow = inlet.m_flow;
      outlet.X = inlet.X;
      outlet.p = p_out;
      rho_in = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, inlet.p, xi);
      outlet.h = inlet.h + (outlet.p - inlet.p)/(rho_in*eta);
      outlet.T = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, outlet.p, outlet.h, xi);
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, outlet.p, outlet.h, xi);
      W_flow = inlet.m_flow*(outlet.h - inlet.h);

      annotation (Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={
            Ellipse(
              extent={{-90,90},{90,-90}},
              lineColor={0,0,0},
              lineThickness=0.5,
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{-55,-45},{55,-45},{0,75},{-55,-45}},
              lineColor={0,0,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{100,70},{200,10}},
              textString="%name",
              textColor={0,0,255},
              horizontalAlignment=TextAlignment.Left),
            Text(
              extent={{100,-10},{200,-70}},
              textString=DynamicSelect("W_p", String(W_flow/1000, format=".2f") + " kW"),
              textColor={0,0,0},
              horizontalAlignment=TextAlignment.Left)}),
        Documentation(info="<html>
<p>Raises the strong solution from the absorber (state 5) to p_out (state 6):
h_out = h_in + (p_out - p_in)/(rho_in*eta).</p>
</html>"));
    end SolutionPump;
  end Components;

  // =====================================================================
  //  SYSTEM MODEL
  // =====================================================================
  model AbsorptionCycleSystem
    "Single-effect NH3-H2O absorption cycle, steady state, built from components"
    extends Modelica.Icons.Example;

    // -------------------- Inputs (same as the EES problem) --------------------
    parameter Modelica.Units.SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
    parameter Modelica.Units.SI.Temperature T_C = 273.15 + 5 "Evaporator temperature";
    parameter Modelica.Units.SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
    parameter Modelica.Units.SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
    parameter Real eta_p = 0.62 "Pump efficiency";
    parameter Modelica.Units.SI.AbsolutePressure P_gen = 1.6e6 "High-side pressure";
    parameter Modelica.Units.SI.AbsolutePressure P_abs = 400e3 "Low-side pressure";
    parameter Modelica.Units.SI.TemperatureDifference DT_cond = 4 "Condenser approach temperature";
    parameter Modelica.Units.SI.TemperatureDifference DT_evap = 3 "Evaporator approach temperature";
    parameter Modelica.Units.SI.MassFlowRate m_dot_r = 0.05 "Refrigerant mass flow rate";

    // -------------------- Components --------------------
    Components.Generator generator(T_gen=T_gen, m_dot_r=m_dot_r)
      annotation (Placement(transformation(extent={{80,70},{140,130}})));
    Components.Condenser condenser(T_out=T_amb + DT_cond)
      annotation (Placement(transformation(extent={{-140,70},{-80,130}})));
    Components.ExpansionValve valve1(p_out=P_abs) "Refrigerant expansion valve"
      annotation (Placement(transformation(extent={{-185,-15},{-155,15}})));
    Components.Evaporator evaporator(T_out=T_C - DT_evap)
      annotation (Placement(transformation(extent={{-140,-130},{-80,-70}})));
    Components.Absorber absorber(T_abs=T_abs)
      annotation (Placement(transformation(extent={{80,-130},{140,-70}})));
    Components.SolutionPump pump(p_out=P_gen, eta=eta_p)
      annotation (Placement(transformation(extent={{155,-15},{185,15}})));
    Components.ExpansionValve valve2(p_out=P_abs) "Solution expansion valve"
      annotation (Placement(transformation(extent={{95,-15},{125,15}})));

    // -------------------- Results in EES state numbering (1-8) --------------------
    Modelica.Units.SI.Temperature T[8] = {valve1.outlet.T, evaporator.outlet.T,
      generator.vapor.T, condenser.outlet.T, absorber.outlet.T, pump.outlet.T,
      generator.liquid.T, valve2.outlet.T} "State temperatures";
    Real T_degC[8] = T .- 273.15 "State temperatures [degC]";
    Modelica.Units.SI.AbsolutePressure P[8] = {valve1.outlet.p, evaporator.outlet.p,
      generator.vapor.p, condenser.outlet.p, absorber.outlet.p, pump.outlet.p,
      generator.liquid.p, valve2.outlet.p} "State pressures";
    Real P_bar[8] = P ./ 1e5 "State pressures [bar]";
    Modelica.Units.SI.SpecificEnthalpy h[8] = {valve1.outlet.h, evaporator.outlet.h,
      generator.vapor.h, condenser.outlet.h, absorber.outlet.h, pump.outlet.h,
      generator.liquid.h, valve2.outlet.h} "State specific enthalpies";
    Real h_kJkg[8] = h ./ 1e3 "State specific enthalpies [kJ/kg]";
    Modelica.Units.SI.MassFraction X[8] = {valve1.outlet.X, evaporator.outlet.X,
      generator.vapor.X, condenser.outlet.X, absorber.outlet.X, pump.outlet.X,
      generator.liquid.X, valve2.outlet.X} "State ammonia mass fractions";
    Modelica.Units.SI.MassFlowRate m_dot[8] = {valve1.outlet.m_flow, evaporator.outlet.m_flow,
      generator.vapor.m_flow, condenser.outlet.m_flow, absorber.outlet.m_flow, pump.outlet.m_flow,
      generator.liquid.m_flow, valve2.outlet.m_flow} "State mass flow rates";
    Real Qu[8] = {valve1.Qu_out, evaporator.Qu_out, 1, condenser.Qu_out, 0, pump.Qu_out, 0,
      valve2.Qu_out} "State vapor qualities";

    Modelica.Units.SI.HeatFlowRate Q_dot_gen = generator.Q_flow "Generator heat input";
    Modelica.Units.SI.HeatFlowRate Q_dot_cond = condenser.Q_flow "Condenser heat rejected";
    Modelica.Units.SI.HeatFlowRate Q_dot_evap = evaporator.Q_flow "Cooling capacity";
    Modelica.Units.SI.HeatFlowRate Q_dot_abs = absorber.Q_flow "Absorber heat rejected";
    Modelica.Units.SI.Power W_dot_p = pump.W_flow "Pump power";
    Real COP = Q_dot_evap/Q_dot_gen "Coefficient of performance";

  equation
    connect(generator.vapor, condenser.inlet) annotation (Line(
        points={{80,112},{-80,112}},
        color={0,127,255},
        thickness=0.5));
    connect(condenser.outlet, valve1.inlet) annotation (Line(
        points={{-140,100},{-170,100},{-170,15}},
        color={0,127,255},
        thickness=0.5));
    connect(valve1.outlet, evaporator.inlet) annotation (Line(
        points={{-170,-15},{-170,-100},{-140,-100}},
        color={0,127,255},
        thickness=0.5));
    connect(evaporator.outlet, absorber.vapor_in) annotation (Line(
        points={{-80,-100},{80,-100}},
        color={0,127,255},
        thickness=0.5));
    connect(absorber.outlet, pump.inlet) annotation (Line(
        points={{140,-100},{170,-100},{170,-15}},
        color={0,127,255},
        thickness=0.5));
    connect(pump.outlet, generator.inlet) annotation (Line(
        points={{170,15},{170,100},{140,100}},
        color={0,127,255},
        thickness=0.5));
    connect(generator.liquid, valve2.inlet) annotation (Line(
        points={{110,70},{110,15}},
        color={0,127,255},
        thickness=0.5));
    connect(valve2.outlet, absorber.liquid_in) annotation (Line(
        points={{110,-15},{110,-70}},
        color={0,127,255},
        thickness=0.5));

    annotation (
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-200,-160},{200,160}}),
        graphics={
          Line(
            points={{-200,0},{200,0}},
            color={160,160,164},
            pattern=LinePattern.Dash),
          Text(
            extent={{-198,158},{-110,148}},
            textString="HIGH PRESSURE",
            textColor={128,128,128},
            horizontalAlignment=TextAlignment.Left),
          Text(
            extent={{-198,-148},{-110,-158}},
            textString="LOW PRESSURE",
            textColor={128,128,128},
            horizontalAlignment=TextAlignment.Left),
          Text(
            extent={{-50,160},{50,146}},
            textString=DynamicSelect("COP", "COP = " + String(COP, format=".3f")),
            textColor={0,0,0}),
          Text(
            extent={{-45,126},{45,116}},
            textString=DynamicSelect("3", "3: " + String(T_degC[3], format=".1f") + " C, X " + String(X[3], format=".3f")),
            textColor={0,0,127}),
          Text(
            extent={{-168,60},{-98,50}},
            textString=DynamicSelect("4", "4: " + String(T_degC[4], format=".1f") + " C, X " + String(X[4], format=".3f")),
            textColor={0,0,127},
            horizontalAlignment=TextAlignment.Left),
          Text(
            extent={{-168,-50},{-98,-60}},
            textString=DynamicSelect("1", "1: " + String(T_degC[1], format=".1f") + " C, X " + String(X[1], format=".3f")),
            textColor={0,0,127},
            horizontalAlignment=TextAlignment.Left),
          Text(
            extent={{-45,-86},{45,-96}},
            textString=DynamicSelect("2", "2: " + String(T_degC[2], format=".1f") + " C, X " + String(X[2], format=".3f")),
            textColor={0,0,127}),
          Text(
            extent={{112,-50},{168,-60}},
            textString=DynamicSelect("5", "5: " + String(T_degC[5], format=".1f") + " C, X " + String(X[5], format=".3f")),
            textColor={0,0,127},
            horizontalAlignment=TextAlignment.Left),
          Text(
            extent={{112,60},{168,50}},
            textString=DynamicSelect("6", "6: " + String(T_degC[6], format=".1f") + " C, X " + String(X[6], format=".3f")),
            textColor={0,0,127},
            horizontalAlignment=TextAlignment.Left),
          Text(
            extent={{40,50},{108,40}},
            textString=DynamicSelect("7", "7: " + String(T_degC[7], format=".1f") + " C, X " + String(X[7], format=".3f")),
            textColor={0,0,127},
            horizontalAlignment=TextAlignment.Right),
          Text(
            extent={{40,-40},{108,-50}},
            textString=DynamicSelect("8", "8: " + String(T_degC[8], format=".1f") + " C, X " + String(X[8], format=".3f")),
            textColor={0,0,127},
            horizontalAlignment=TextAlignment.Right)}),
      experiment(StopTime=1),
      Documentation(info="<html>
<p>Single-effect NH3-H2O absorption cycle (EES states 1-8) assembled from
components. Same equations and inputs as the flat model AbsorptionCycle_001.</p>
<ul>
<li>High side: pump sets P_gen; generator and condenser share it.</li>
<li>Low side: both expansion valves set P_abs; evaporator and absorber share it.</li>
<li>Arrays T, T_degC, P, P_bar, h, h_kJkg, X, m_dot, Qu list the results in
EES state numbering for direct comparison.</li>
</ul>
<p>After simulating, open the diagram in the Simulation tab: component icons show
their heat duties and the labels show T and X at each state.</p>
</html>"));
  end AbsorptionCycleSystem;

  annotation (uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")),
    Documentation(info="<html>
<p>Component-based, steady-state single-effect NH3-H2O absorption cycle using
TILMedia_WaterAmmonia_nc2. Run <b>AbsorptionCycleSystem</b>.</p>
</html>"));
end AbsorptionCycleComponents;
