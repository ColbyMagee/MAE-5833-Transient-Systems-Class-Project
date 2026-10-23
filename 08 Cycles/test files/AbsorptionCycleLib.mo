within ;
package AbsorptionCycleLib
  "Steady-state, connectable components for a single-effect NH3-H2O absorption cycle (TILMedia 2024.1)"

  // =====================================================================
  //  Interfaces
  // =====================================================================
  package Interfaces "Connectors and partial models"

    partial connector FluidPort "Steady-state NH3-H2O stream connector"
      Modelica.Units.SI.AbsolutePressure p "Pressure";
      flow Modelica.Units.SI.MassFlowRate m_flow
        "Mass flow rate INTO the component (positive = entering)";
      stream Modelica.Units.SI.SpecificEnthalpy h_outflow
        "Specific enthalpy of the fluid if it leaves through this port";
      stream Real X_outflow(min = 0, max = 1)
        "Ammonia mass fraction of the fluid if it leaves through this port";
    end FluidPort;

    connector FluidPort_a "Fluid inlet (filled circle)"
      extends FluidPort;
      annotation (Icon(graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,90,180},
              fillColor={0,90,180},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_a;

    connector FluidPort_b "Fluid outlet (hollow circle)"
      extends FluidPort;
      annotation (Icon(graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,90,180},
              lineThickness=0.5,
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_b;

    partial model PartialNH3H2O "Common fluid definition for all components"
      replaceable parameter TILMedia.VLEFluidTypes.TILMedia_WaterAmmonia_nc2 vleFluidType
        constrainedby TILMedia.VLEFluidTypes.BaseVLEFluid
        "NH3-H2O working fluid"
        annotation (choicesAllMatching=true);
      parameter Boolean xiIsWater = true
        "true: TILMedia xi[1] is the water mass fraction (xi = 1 - X_NH3)";
    end PartialNH3H2O;

    partial model PartialTwoPort "Two-port flow-through component"
      extends PartialNH3H2O;
      FluidPort_a port_a "Inlet"
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
      FluidPort_b port_b "Outlet"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));
      Modelica.Units.SI.SpecificEnthalpy h_in = inStream(port_a.h_outflow)
        "Inlet enthalpy";
      Real X_in = inStream(port_a.X_outflow) "Inlet ammonia mass fraction";
      Modelica.Units.SI.MassFlowRate m_flow = port_a.m_flow "Mass flow rate";
    equation
      // Steady-state mass and species balance (composition passes through)
      port_a.m_flow + port_b.m_flow = 0;
      port_b.X_outflow = X_in;
      // Reverse-direction stream values (not used for design-point flow)
      port_a.h_outflow = inStream(port_b.h_outflow);
      port_a.X_outflow = inStream(port_b.X_outflow);
    end PartialTwoPort;
  end Interfaces;

  // =====================================================================
  //  Functions
  // =====================================================================
  package Functions "Helper functions"
    function xiOf "TILMedia composition vector from ammonia mass fraction"
      input Real X "Ammonia mass fraction";
      input Boolean xiIsWater = true "true: xi[1] is water mass fraction";
      output Real xi[1] "TILMedia composition vector";
    algorithm
      xi := {if xiIsWater then 1 - X else X};
      annotation (Inline=true);
    end xiOf;
  end Functions;

  // =====================================================================
  //  Components
  // =====================================================================
  package Components "Cycle components"

    model ThermalCompressor
      "Generator + absorber + solution pump + solution valve (states 2-8 of the EES model)"
      extends AbsorptionCycleLib.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorptionCycleLib.Functions.xiOf;

      // -------------------- Parameters --------------------
      parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
      parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
      parameter SI.AbsolutePressure P_gen = 1.6e6 "Generator (high-side) pressure";
      parameter SI.AbsolutePressure P_abs = 400e3 "Absorber (low-side) pressure";
      parameter Real eta_p = 0.62 "Solution pump efficiency";
      parameter SI.MassFlowRate m_dot_r = 0.05
        "Refrigerant vapor mass flow leaving the generator (sets the loop flow)";

      parameter Real X3_start = 0.97 "Start: generator vapor NH3 fraction";
      parameter Real X5_start = 0.47 "Start: strong solution NH3 fraction";
      parameter Real X7_start = 0.38 "Start: weak solution NH3 fraction";

      // -------------------- Ports --------------------
      AbsorptionCycleLib.Interfaces.FluidPort_a vaporIn
        "Refrigerant from evaporator into absorber (state 2)"
        annotation (Placement(transformation(extent={{-110,-70},{-90,-50}})));
      AbsorptionCycleLib.Interfaces.FluidPort_b vaporOut
        "Refrigerant vapor from generator to condenser (state 3)"
        annotation (Placement(transformation(extent={{-110,50},{-90,70}})));

      Modelica.Blocks.Interfaces.RealOutput Q_flow_gen(unit="W", start=8e4)
        "Generator heat input"
        annotation (Placement(transformation(extent={{100,50},{120,70}})));
      Modelica.Blocks.Interfaces.RealOutput P_pump(unit="W") "Solution pump power"
        annotation (Placement(transformation(extent={{100,-10},{120,10}})));
      Modelica.Blocks.Interfaces.RealOutput Q_flow_abs(unit="W")
        "Absorber heat rejection"
        annotation (Placement(transformation(extent={{100,-70},{120,-50}})));

      // -------------------- Internal states --------------------
      // State 2 (inlet, from connection)
      SI.SpecificEnthalpy h2 "Inlet enthalpy (state 2)";
      Real X2 "Inlet NH3 fraction (state 2)";
      // State 3: saturated vapor leaving generator
      SI.SpecificEnthalpy h3 "State 3 enthalpy";
      Real X3(start = X3_start, min = 0, max = 1) "State 3 NH3 fraction";
      // State 5: saturated strong solution leaving absorber
      SI.SpecificEnthalpy h5 "State 5 enthalpy";
      Real X5(start = X5_start, min = 0, max = 1) "State 5 NH3 fraction";
      SI.Density rho5 "State 5 density";
      // State 6: pump outlet
      SI.SpecificEnthalpy h6 "State 6 enthalpy";
      SI.Temperature T6 "State 6 temperature";
      Real Qu6 "State 6 vapor quality";
      // State 7: saturated weak solution leaving generator
      SI.SpecificEnthalpy h7 "State 7 enthalpy";
      Real X7(start = X7_start, min = 0, max = 1) "State 7 NH3 fraction";
      // State 8: solution valve outlet
      SI.SpecificEnthalpy h8 "State 8 enthalpy";
      SI.Temperature T8 "State 8 temperature";
      Real Qu8 "State 8 vapor quality";

      // -------------------- Flows --------------------
      SI.MassFlowRate m_dot_r_in "Refrigerant entering absorber";
      SI.MassFlowRate m_dot_r_out "Refrigerant leaving generator";
      SI.MassFlowRate m_dot_abs(start = 0.35) "Strong solution, absorber -> generator";
      SI.MassFlowRate m_dot_gen(start = 0.3) "Weak solution, generator -> absorber";
      Real f = m_dot_abs / max(m_dot_r_out, 1e-8) "Circulation ratio";

    equation
      // ===================== Port boundary conditions =====================
      vaporOut.p = P_gen;
      vaporIn.p  = P_abs;
      vaporOut.m_flow = -m_dot_r;      // the only flow specification in the loop
      m_dot_r_out = -vaporOut.m_flow;
      m_dot_r_in  =  vaporIn.m_flow;

      h2 = inStream(vaporIn.h_outflow);
      X2 = inStream(vaporIn.X_outflow);

      vaporOut.h_outflow = h3;
      vaporOut.X_outflow = X3;
      vaporIn.h_outflow  = h5;         // only used if flow reverses
      vaporIn.X_outflow  = X5;

      // ===================== State 3 (dew point at P_gen, T_gen) =====================
      T_gen = TILMedia.VLEFluidFunctions.dewTemperature_pxi(vleFluidType, P_gen, xiOf(X3, xiIsWater));
      h3    = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(vleFluidType, P_gen, xiOf(X3, xiIsWater));

      // ===================== State 5 (bubble point at P_abs, T_abs) =====================
      T_abs = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P_abs, xiOf(X5, xiIsWater));
      h5    = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P_abs, xiOf(X5, xiIsWater));
      rho5  = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, P_abs, xiOf(X5, xiIsWater));

      // ===================== State 6 (pump outlet) =====================
      h6  = h5 + (P_gen - P_abs) / (rho5 * eta_p);
      T6  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P_gen, h6, xiOf(X5, xiIsWater));
      Qu6 = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P_gen, h6, xiOf(X5, xiIsWater));

      // ===================== State 7 (bubble point at P_gen, T_gen) =====================
      T_gen = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(vleFluidType, P_gen, xiOf(X7, xiIsWater));
      h7    = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(vleFluidType, P_gen, xiOf(X7, xiIsWater));

      // ===================== State 8 (solution valve, isenthalpic) =====================
      h8  = h7;
      T8  = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, P_abs, h8, xiOf(X7, xiIsWater));
      Qu8 = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, P_abs, h8, xiOf(X7, xiIsWater));

      // ===================== Absorber balances =====================
      // (Generator mass/species balances follow automatically at steady state,
      //  so they are not written again - that would over-determine the closed loop.)
      m_dot_r_in + m_dot_gen = m_dot_abs;
      m_dot_r_in * X2 + m_dot_gen * X7 = m_dot_abs * X5;
      m_dot_r_in * h2 + m_dot_gen * h8 = Q_flow_abs + m_dot_abs * h5;

      // ===================== Pump and generator energy =====================
      P_pump = m_dot_abs * (h6 - h5);
      m_dot_abs * h6 + Q_flow_gen = m_dot_r_out * h3 + m_dot_gen * h7;

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-100,100},{100,-100}}, lineColor={95,95,95},
              fillColor={250,250,250}, fillPattern=FillPattern.Solid, radius=6),
            Rectangle(extent={{-60,92},{60,32}}, lineColor={170,40,40},
              fillColor={255,200,190}, fillPattern=FillPattern.Solid),
            Text(extent={{-58,74},{58,50}}, textColor={130,20,20}, textString="Generator"),
            Rectangle(extent={{-60,-32},{60,-92}}, lineColor={30,80,160},
              fillColor={190,215,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-58,-50},{58,-74}}, textColor={20,50,130}, textString="Absorber"),
            // solution pump (strong solution up, right side)
            Line(points={{40,-32},{40,32}}, color={0,0,0}),
            Ellipse(extent={{26,-14},{54,14}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Polygon(points={{32,-7},{48,-7},{40,9},{32,-7}}, lineColor={0,0,0},
              fillColor={0,0,0}, fillPattern=FillPattern.Solid),
            // solution valve (weak solution down, left side)
            Line(points={{-40,32},{-40,-32}}, color={0,0,0}),
            Polygon(points={{-50,12},{-30,12},{-50,-12},{-30,-12},{-50,12}},
              lineColor={0,0,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            // refrigerant lines to ports
            Line(points={{-100,60},{-60,60}}, color={0,90,180}, thickness=0.5),
            Line(points={{-100,-60},{-60,-60}}, color={0,90,180}, thickness=0.5),
            Text(extent={{-150,145},{150,108}}, textColor={0,0,255}, textString="%name")}),
        Documentation(info="<html>
<p>Combined generator / absorber (\"thermal compressor\") of a single-effect
NH3-H2O absorption cycle, steady state. Contains the absorber, solution pump,
generator and solution expansion valve (states 5-8 of the EES model).</p>
<ul>
<li><b>vaporIn</b> (state 2): refrigerant from the evaporator, enters the absorber.</li>
<li><b>vaporOut</b> (state 3): saturated vapor from the generator, goes to the condenser.</li>
<li>Outputs: generator heat input, absorber heat rejection, pump power (W).</li>
</ul>
<p>This component sets both cycle pressures (P_gen at vaporOut, P_abs at
vaporIn) and the refrigerant flow m_dot_r. The other loop components must
therefore not impose pressure or flow; they only pass them along.</p>
<p>Saturated states are found as in the EES model: at fixed P, the bubble (Q=0)
or dew (Q=1) temperature equation determines the composition X.</p>
</html>"));
    end ThermalCompressor;

    model Condenser "Refrigerant condenser with fixed outlet temperature"
      extends AbsorptionCycleLib.Interfaces.PartialTwoPort;
      import SI = Modelica.Units.SI;
      parameter SI.Temperature T_out = 273.15 + 29 "Outlet temperature (state 4)";
      Real Qu_out "Outlet vapor quality";
      Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Heat rejected"
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=90, origin={0,110})));
    equation
      port_b.p = port_a.p;
      port_b.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
        vleFluidType, port_a.p, T_out, AbsorptionCycleLib.Functions.xiOf(X_in, xiIsWater));
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, port_a.p, port_b.h_outflow, AbsorptionCycleLib.Functions.xiOf(X_in, xiIsWater));
      Q_flow = m_flow * (h_in - port_b.h_outflow);
      annotation (Icon(graphics={
            Rectangle(extent={{-80,40},{80,-40}}, lineColor={170,40,40},
              fillColor={255,225,215}, fillPattern=FillPattern.Solid),
            Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
              {30,20},{50,-20},{60,0},{100,0}}, color={0,90,180}, thickness=0.5),
            Text(extent={{-80,-44},{80,-70}}, textColor={130,20,20}, textString="Condenser"),
            Text(extent={{-150,90},{150,56}}, textColor={0,0,255}, textString="%name")}));
    end Condenser;

    model ExpansionValve "Isenthalpic refrigerant expansion valve"
      extends AbsorptionCycleLib.Interfaces.PartialTwoPort;
      import SI = Modelica.Units.SI;
      SI.Temperature T_out "Outlet temperature";
      Real Qu_out "Outlet vapor quality";
    equation
      // No pressure equation: the outlet pressure is set by the downstream side.
      port_b.h_outflow = h_in;
      T_out = TILMedia.VLEFluidFunctions.temperature_phxi(
        vleFluidType, port_b.p, h_in, AbsorptionCycleLib.Functions.xiOf(X_in, xiIsWater));
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, port_b.p, h_in, AbsorptionCycleLib.Functions.xiOf(X_in, xiIsWater));
      annotation (Icon(graphics={
            Polygon(points={{-80,40},{-80,-40},{0,0},{-80,40}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Polygon(points={{80,40},{80,-40},{0,0},{80,40}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Line(points={{-100,0},{-80,0}}, color={0,90,180}, thickness=0.5),
            Line(points={{80,0},{100,0}}, color={0,90,180}, thickness=0.5),
            Text(extent={{-150,90},{150,50}}, textColor={0,0,255}, textString="%name")}));
    end ExpansionValve;

    model Evaporator "Refrigerant evaporator with fixed outlet temperature"
      extends AbsorptionCycleLib.Interfaces.PartialTwoPort;
      import SI = Modelica.Units.SI;
      parameter SI.Temperature T_out = 273.15 + 2 "Outlet temperature (state 2)";
      Real Qu_out "Outlet vapor quality";
      Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Cooling capacity"
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=270, origin={0,-110})));
    equation
      port_b.p = port_a.p;
      port_b.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
        vleFluidType, port_a.p, T_out, AbsorptionCycleLib.Functions.xiOf(X_in, xiIsWater));
      Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, port_a.p, port_b.h_outflow, AbsorptionCycleLib.Functions.xiOf(X_in, xiIsWater));
      Q_flow = m_flow * (port_b.h_outflow - h_in);
      annotation (Icon(graphics={
            Rectangle(extent={{-80,40},{80,-40}}, lineColor={30,80,160},
              fillColor={215,235,255}, fillPattern=FillPattern.Solid),
            Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
              {30,20},{50,-20},{60,0},{100,0}}, color={0,90,180}, thickness=0.5),
            Text(extent={{-80,70},{80,44}}, textColor={20,50,130}, textString="Evaporator"),
            Text(extent={{-150,-56},{150,-90}}, textColor={0,0,255}, textString="%name")}));
    end Evaporator;
  end Components;

  // =====================================================================
  //  Examples
  // =====================================================================
  package Examples "Test models"
    model SingleEffectCycle
      "Same cycle as AbsorptionCycle_001, assembled from connectable components"
      import SI = Modelica.Units.SI;

      parameter Boolean xiIsWater = true "See PartialNH3H2O";
      parameter SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
      parameter SI.Temperature T_C = 273.15 + 5 "Evaporator temperature";
      parameter SI.TemperatureDifference DT_cond = 4 "Condenser approach";
      parameter SI.TemperatureDifference DT_evap = 3 "Evaporator approach";

      AbsorptionCycleLib.Components.ThermalCompressor thermalCompressor(
        xiIsWater=xiIsWater,
        T_gen=273.15 + 90,
        T_abs=273.15 + 32,
        P_gen=1.6e6,
        P_abs=400e3,
        eta_p=0.62,
        m_dot_r=0.05)
        annotation (Placement(transformation(extent={{40,-20},{80,20}})));
      AbsorptionCycleLib.Components.Condenser condenser(
        xiIsWater=xiIsWater, T_out=T_amb + DT_cond)
        annotation (Placement(transformation(extent={{20,40},{-20,60}})));
      AbsorptionCycleLib.Components.ExpansionValve valve(xiIsWater=xiIsWater)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=270, origin={-60,0})));
      AbsorptionCycleLib.Components.Evaporator evaporator(
        xiIsWater=xiIsWater, T_out=T_C - DT_evap)
        annotation (Placement(transformation(extent={{-20,-60},{20,-40}})));

      Real COP = evaporator.Q_flow / thermalCompressor.Q_flow_gen
        "Coefficient of performance";

    equation
      connect(thermalCompressor.vaporOut, condenser.port_a)
        annotation (Line(points={{40,12},{30,12},{30,50},{20,50}}, color={0,90,180}, thickness=0.5));
      connect(condenser.port_b, valve.port_a)
        annotation (Line(points={{-20,50},{-60,50},{-60,10}}, color={0,90,180}, thickness=0.5));
      connect(valve.port_b, evaporator.port_a)
        annotation (Line(points={{-60,-10},{-60,-50},{-20,-50}}, color={0,90,180}, thickness=0.5));
      connect(evaporator.port_b, thermalCompressor.vaporIn)
        annotation (Line(points={{20,-50},{30,-50},{30,-12},{40,-12}}, color={0,90,180}, thickness=0.5));
      annotation (experiment(StopTime=1));
    end SingleEffectCycle;
  end Examples;

  annotation (uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")));
end AbsorptionCycleLib;
