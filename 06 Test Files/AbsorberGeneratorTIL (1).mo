within ;
package AbsorberGeneratorTIL
  "NH3-H2O generator/absorber with TIL-style ports: connect a pump, condenser, throttling valve and evaporator"

  // =====================================================================
  //  MAIN COMPONENT
  // =====================================================================
  model AbsorberGenerator
    "Generator + absorber (with integrated solution valve) for connection to TIL components"
    extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
    import SI = Modelica.Units.SI;

    // ---------------- Generator ----------------
    parameter Boolean specifyGeneratorPressure = false
      "= true: P_gen is known and the generator temperature is calculated"
      annotation (Dialog(group="Generator"), choices(checkBox=true), Evaluate=true);
    parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature"
      annotation (Dialog(group="Generator", enable=not specifyGeneratorPressure));
    parameter SI.AbsolutePressure P_gen = 1.6e6 "Generator pressure"
      annotation (Dialog(group="Generator", enable=specifyGeneratorPressure));

    // ---------------- Absorber ----------------
    parameter Boolean specifyStrongConcentration = false
      "= true: strong-solution NH3 fraction is known and the absorber pressure is calculated"
      annotation (Dialog(group="Absorber"), choices(checkBox=true), Evaluate=true);
    parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature"
      annotation (Dialog(group="Absorber"));
    parameter SI.AbsolutePressure P_abs = 400e3 "Absorber pressure"
      annotation (Dialog(group="Absorber", enable=not specifyStrongConcentration));
    parameter Real X_strong = 0.47 "Strong-solution NH3 mass fraction"
      annotation (Dialog(group="Absorber", enable=specifyStrongConcentration));

    // ---------------- Vapor connections ----------------
    parameter Boolean idealVaporPorts = false
      "= true: no pressure drop between generator/condenser and evaporator/absorber"
      annotation (Dialog(group="Vapor connections"), choices(checkBox=true), Evaluate=true);
    parameter SI.PressureDifference dp_vapor_nominal = 1e3
      "Vapor-line pressure drop at nominal flow"
      annotation (Dialog(group="Vapor connections", enable=not idealVaporPorts));
    parameter SI.MassFlowRate m_flow_vapor_nominal = 0.05
      "Nominal refrigerant flow"
      annotation (Dialog(group="Vapor connections", enable=not idealVaporPorts));

    // ---------------- Start values ----------------
    parameter SI.AbsolutePressure p_gen_start = 1.6e6 "Generator pressure"
      annotation (Dialog(tab="Initialization"));
    parameter SI.AbsolutePressure p_abs_start = 400e3 "Absorber pressure"
      annotation (Dialog(tab="Initialization"));
    parameter Real X3_start = 0.97 "Refrigerant vapor NH3 fraction"
      annotation (Dialog(tab="Initialization"));
    parameter Real X5_start = 0.47 "Strong-solution NH3 fraction"
      annotation (Dialog(tab="Initialization"));
    parameter Real X7_start = 0.38 "Weak-solution NH3 fraction"
      annotation (Dialog(tab="Initialization"));
    parameter SI.MassFlowRate m_r_start = 0.05 "Refrigerant flow"
      annotation (Dialog(tab="Initialization"));
    parameter SI.MassFlowRate m_ss_start = 0.33 "Strong-solution flow"
      annotation (Dialog(tab="Initialization"));

    // ---------------- Connectors ----------------
    AbsorberGeneratorTIL.Interfaces.VLEFluidPort vaporOut
      "Refrigerant vapor to the condenser (state 3)"
      annotation (Placement(transformation(extent={{-110,50},{-90,70}})));
    AbsorberGeneratorTIL.Interfaces.VLEFluidPort vaporIn
      "Refrigerant from the evaporator (state 2)"
      annotation (Placement(transformation(extent={{-110,-70},{-90,-50}})));
    AbsorberGeneratorTIL.Interfaces.VLEFluidPort strongIn
      "Strong solution from the pump outlet (state 6)"
      annotation (Placement(transformation(extent={{90,50},{110,70}})));
    AbsorberGeneratorTIL.Interfaces.VLEFluidPort strongOut
      "Strong solution to the pump inlet (state 5)"
      annotation (Placement(transformation(extent={{90,-70},{110,-50}})));
    Modelica.Blocks.Interfaces.RealOutput Q_flow_gen(unit="W") "Generator heat input"
      annotation (Placement(transformation(extent={{100,10},{120,30}})));
    Modelica.Blocks.Interfaces.RealOutput Q_flow_abs(unit="W") "Absorber heat rejection"
      annotation (Placement(transformation(extent={{100,-30},{120,-10}})));

    // ---------------- Sub-components ----------------
    AbsorberGeneratorTIL.Components.Generator generator(
      final vleFluidType=vleFluidType,
      final xiIsWater=xiIsWater,
      final specifyPressure=specifyGeneratorPressure,
      final T_gen=T_gen,
      final P_gen=P_gen,
      final idealVaporPort=idealVaporPorts,
      final dp_vapor_nominal=dp_vapor_nominal,
      final m_flow_vapor_nominal=m_flow_vapor_nominal,
      final p_start=p_gen_start,
      final X3_start=X3_start,
      final X7_start=X7_start,
      final m_r_start=m_r_start,
      final m_ss_start=m_ss_start)
      annotation (Placement(transformation(extent={{-20,20},{20,60}})));
    AbsorberGeneratorTIL.Components.Absorber absorber(
      final vleFluidType=vleFluidType,
      final xiIsWater=xiIsWater,
      final specifyConcentration=specifyStrongConcentration,
      final T_abs=T_abs,
      final P_abs=P_abs,
      final X_strong=X_strong,
      final idealVaporPort=idealVaporPorts,
      final dp_vapor_nominal=dp_vapor_nominal,
      final m_flow_vapor_nominal=m_flow_vapor_nominal,
      final p_start=p_abs_start,
      final X5_start=X5_start,
      final m_r_start=m_r_start,
      final m_ss_start=m_ss_start)
      annotation (Placement(transformation(extent={{-20,-60},{20,-20}})));

    // ---------------- Results ----------------
    SI.AbsolutePressure P_high = generator.p_gen
      "Generator pressure (result unless specifyGeneratorPressure)";
    SI.AbsolutePressure P_low = absorber.p_abs "Absorber pressure";
    SI.Temperature T_generator = generator.T_gen_actual "Generator temperature";
    SI.MassFlowRate m_refrigerant = generator.m_r "Refrigerant flow (result)";
    SI.MassFlowRate m_strong = generator.m_ss "Strong-solution flow (set by the pump)";
    SI.MassFlowRate m_weak = generator.m_ws "Weak-solution flow";
    Real circulationRatio = m_strong/max(m_refrigerant, 1e-8)
      "Strong-solution flow per unit refrigerant flow";
    Real X_refrigerant = generator.X3 "Refrigerant vapor NH3 mass fraction";
    Real X_strongSolution = absorber.X5 "Strong-solution NH3 mass fraction";
    Real X_weakSolution = generator.X7 "Weak-solution NH3 mass fraction";

  equation
    connect(strongIn, generator.strongIn)
      annotation (Line(points={{100,60},{60,60},{60,48},{20,48}}, color={120,60,160}, thickness=0.5));
    connect(generator.vaporOut, vaporOut)
      annotation (Line(points={{-20,48},{-60,48},{-60,60},{-100,60}}, color={200,40,40}, thickness=0.5));
    connect(generator.weakOut, absorber.weakIn)
      annotation (Line(points={{0,20},{0,-20}}, color={120,60,160}, thickness=0.5));
    connect(vaporIn, absorber.vaporIn)
      annotation (Line(points={{-100,-60},{-60,-60},{-60,-44},{-20,-44}}, color={0,90,200}, thickness=0.5));
    connect(absorber.strongOut, strongOut)
      annotation (Line(points={{20,-50},{60,-50},{60,-60},{100,-60}}, color={120,60,160}, thickness=0.5));
    connect(generator.Q_flow_gen, Q_flow_gen)
      annotation (Line(points={{22,34},{80,34},{80,20},{110,20}}, color={0,0,127}));
    connect(absorber.Q_flow_abs, Q_flow_abs)
      annotation (Line(points={{22,-36},{80,-36},{80,-20},{110,-20}}, color={0,0,127}));

    annotation (
      Icon(coordinateSystem(preserveAspectRatio=false), graphics={
          Rectangle(extent={{-100,100},{100,-100}}, lineColor={95,95,95},
            fillColor={250,250,250}, fillPattern=FillPattern.Solid, radius=6),
          // generator
          Rectangle(extent={{-60,90},{60,30}}, lineColor={170,40,40},
            fillColor={255,200,190}, fillPattern=FillPattern.Solid),
          Rectangle(extent={{-58,50},{58,32}}, pattern=LinePattern.None,
            fillColor={240,150,130}, fillPattern=FillPattern.Solid),
          Text(extent={{-56,84},{56,56}}, textColor={130,20,20}, textString="Generator"),
          // absorber
          Rectangle(extent={{-60,-30},{60,-90}}, lineColor={30,80,160},
            fillColor={190,215,255}, fillPattern=FillPattern.Solid),
          Rectangle(extent={{-58,-70},{58,-88}}, pattern=LinePattern.None,
            fillColor={140,180,240}, fillPattern=FillPattern.Solid),
          Text(extent={{-56,-36},{56,-64}}, textColor={20,50,130}, textString="Absorber"),
          // weak solution through the integrated solution valve
          Line(points={{-40,30},{-40,-30}}, color={120,60,160}, thickness=0.5),
          Polygon(points={{-50,10},{-30,10},{-40,0},{-50,10}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          Polygon(points={{-50,-10},{-30,-10},{-40,0},{-50,-10}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          // refrigerant ports (left)
          Line(points={{-100,60},{-60,60}}, color={200,40,40}, thickness=0.5),
          Line(points={{-100,-60},{-60,-60}}, color={0,90,200}, thickness=0.5),
          Text(extent={{-98,76},{-62,66}}, textColor={200,40,40}, textString="to condenser"),
          Text(extent={{-98,-66},{-62,-76}}, textColor={0,90,200}, textString="from evaporator"),
          // strong-solution ports (right, to the external pump)
          Line(points={{60,60},{100,60}}, color={120,60,160}, thickness=0.5),
          Line(points={{60,-60},{100,-60}}, color={120,60,160}, thickness=0.5),
          Text(extent={{62,76},{98,66}}, textColor={120,60,160}, textString="from pump"),
          Text(extent={{62,-66},{98,-76}}, textColor={120,60,160}, textString="to pump"),
          // heat outputs
          Text(extent={{64,28},{98,12}}, textColor={200,60,0}, textString="Q_gen"),
          Text(extent={{64,-12},{98,-28}}, textColor={0,90,200}, textString="Q_abs"),
          // state labels
          Ellipse(extent={{-86,44},{-74,56}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-86,44},{-74,56}}, textColor={0,0,0}, textString="3"),
          Ellipse(extent={{-86,-56},{-74,-44}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-86,-56},{-74,-44}}, textColor={0,0,0}, textString="2"),
          Ellipse(extent={{74,44},{86,56}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{74,44},{86,56}}, textColor={0,0,0}, textString="6"),
          Ellipse(extent={{74,-56},{86,-44}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{74,-56},{86,-44}}, textColor={0,0,0}, textString="5"),
          Ellipse(extent={{-28,14},{-16,26}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-28,14},{-16,26}}, textColor={0,0,0}, textString="7"),
          Ellipse(extent={{-28,-26},{-16,-14}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-28,-26},{-16,-14}}, textColor={0,0,0}, textString="8"),
          Text(extent={{-150,140},{150,104}}, textColor={0,0,255}, textString="%name")}),
      Diagram(coordinateSystem(preserveAspectRatio=false)),
      Documentation(info="<html>
<p>Generator and absorber of a single-effect NH3-H2O absorption cycle, steady state
(no fluid storage). Its ports carry the same p, m_flow, h_outflow and xi_outflow as
TIL's VLEFluid connector. The solution expansion
valve (7 &rarr; 8) is built in. The solution pump, condenser, refrigerant throttling
valve and evaporator are connected from outside, for example TIL components.</p>
<h4>Connections</h4>
<ul>
<li><b>vaporOut</b> (state 3) &rarr; condenser inlet</li>
<li><b>vaporIn</b> (state 2) &larr; evaporator outlet</li>
<li><b>strongOut</b> (state 5) &rarr; pump inlet</li>
<li><b>strongIn</b> (state 6) &larr; pump outlet</li>
</ul>
<h4>Who sets what</h4>
<table border=\"1\" cellpadding=\"3\">
<tr><th>Quantity</th><th>Set by</th></tr>
<tr><td>Strong-solution flow</td><td>pump (known)</td></tr>
<tr><td>Pump pressure rise and outlet state</td><td>pump (result: it delivers whatever the generator pressure is)</td></tr>
<tr><td>Generator pressure P_gen</td><td>result: generator equilibrium at T_gen + refrigerant valve flow law</td></tr>
<tr><td>Refrigerant flow</td><td>result: ammonia balance of the generator</td></tr>
<tr><td>Absorber pressure P_abs</td><td>known (stands in for the system charge)</td></tr>
<tr><td>Weak-solution flow</td><td>result: generator mass balance</td></tr>
</table>
<p>Knowns of this component: T_gen, T_abs and P_abs. Use the check boxes to swap
T_gen for P_gen, or P_abs for the strong-solution concentration.</p>
<p>Without solution storage, a steady-state cycle has one free level (the total
ammonia charge). P_abs fixes it. Removing P_abs needs a dynamic absorber with
liquid inventory.</p>
<h4>Vapor connections</h4>
<p>By default the vapor ports have a small linear pressure drop
(dp_vapor_nominal at m_flow_vapor_nominal). This makes the ports flow-type, so
they connect cleanly to TIL heat exchangers that carry their own pressure state.
Set idealVaporPorts = true for no pressure drop.</p>
<h4>Dynamic TIL components</h4>
<p>This component stores no mass. With dynamic TIL heat exchangers, the absorber
acts as a pressure reference (like a TIL boundary). absorber.massImbalance and
absorber.ammoniaImbalance show the mismatch during transients; both are zero at
steady state.</p>
</html>"));
  end AbsorberGenerator;

  // =====================================================================
  //  Components
  // =====================================================================
  package Components "Generator and absorber, usable separately"

    model Generator "Generator with integrated solution expansion valve"
      extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorberGeneratorTIL.Functions.xiOf;
      import AbsorberGeneratorTIL.Functions.XOf;

      // ---------------- Known quantity ----------------
      parameter Boolean specifyPressure = false
        "= true: P_gen is known and T_gen is calculated"
        annotation (Dialog(group="Known quantity"), choices(checkBox=true), Evaluate=true);
      parameter SI.Temperature T_gen = 273.15 + 90
        "Generator temperature (used if specifyPressure = false)"
        annotation (Dialog(group="Known quantity", enable=not specifyPressure));
      parameter SI.AbsolutePressure P_gen = 1.6e6
        "Generator pressure (used if specifyPressure = true)"
        annotation (Dialog(group="Known quantity", enable=specifyPressure));

      // ---------------- Vapor connection ----------------
      parameter Boolean idealVaporPort = false
        "= true: vaporOut.p equals the generator pressure (no vapor-line pressure drop)"
        annotation (Dialog(group="Vapor connection"), choices(checkBox=true), Evaluate=true);
      parameter SI.PressureDifference dp_vapor_nominal = 1e3
        "Vapor-line pressure drop at nominal flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));
      parameter SI.MassFlowRate m_flow_vapor_nominal = 0.05
        "Nominal refrigerant vapor flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));

      // ---------------- Start values ----------------
      parameter SI.AbsolutePressure p_start = 1.6e6 "Generator pressure"
        annotation (Dialog(tab="Initialization"));
      parameter Real X3_start = 0.97 "Vapor NH3 mass fraction"
        annotation (Dialog(tab="Initialization"));
      parameter Real X7_start = 0.38 "Weak-solution NH3 mass fraction"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_r_start = 0.05 "Refrigerant flow"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_ss_start = 0.33 "Strong-solution flow"
        annotation (Dialog(tab="Initialization"));

      // ---------------- Connectors ----------------
      AbsorberGeneratorTIL.Interfaces.VLEFluidPort strongIn(p(start=p_start), m_flow(start=m_ss_start))
        "Strong solution from the pump (state 6)"
        annotation (Placement(transformation(extent={{90,30},{110,50}})));
      AbsorberGeneratorTIL.Interfaces.VLEFluidPort vaporOut(p(start=p_start), m_flow(start=-m_r_start))
        "Refrigerant vapor to the condenser (state 3)"
        annotation (Placement(transformation(extent={{-110,30},{-90,50}})));
      AbsorberGeneratorTIL.Interfaces.VLEFluidPort weakOut(m_flow(start=-(m_ss_start - m_r_start)))
        "Weak solution after the solution valve, to the absorber (state 8)"
        annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
      Modelica.Blocks.Interfaces.RealOutput Q_flow_gen(unit="W") "Generator heat input"
        annotation (Placement(transformation(extent={{100,-40},{120,-20}})));

      // ---------------- Variables ----------------
      SI.AbsolutePressure p_gen(start=p_start) "Generator pressure";
      SI.Temperature T_gen_actual(start=T_gen) "Generator temperature";
      Real X3(start=X3_start, min=0, max=1) "State 3: vapor NH3 mass fraction (dew point)";
      Real X7(start=X7_start, min=0, max=1)
        "State 7: weak-solution NH3 mass fraction (bubble point)";
      SI.SpecificEnthalpy h3 "State 3: saturated vapor enthalpy";
      SI.SpecificEnthalpy h7 "State 7: saturated liquid enthalpy";
      SI.SpecificEnthalpy h6 = inStream(strongIn.h_outflow) "State 6: enthalpy from the pump";
      Real xi6[vleFluidType.nc - 1] = inStream(strongIn.xi_outflow)
        "State 6: TILMedia composition from the pump";
      Real X6 = XOf(xi6, xiIsWater) "State 6: NH3 mass fraction from the pump";
      SI.MassFlowRate m_ss = strongIn.m_flow "Strong solution in (set by the pump)";
      SI.MassFlowRate m_r = -vaporOut.m_flow "Refrigerant vapor out";
      SI.MassFlowRate m_ws = -weakOut.m_flow "Weak solution out";
      SI.Temperature T8 "State 8: temperature after the solution valve";
      Real Qu8 "State 8: vapor quality after the solution valve";
    protected
      final parameter Real k_vapor(unit="kg/(s.Pa)") = m_flow_vapor_nominal/dp_vapor_nominal
        "Vapor-line flow conductance";

    equation
      // ---------------- Known quantity ----------------
      if specifyPressure then
        p_gen = P_gen;
      else
        T_gen_actual = T_gen;
      end if;

      // ---------------- Port pressures and flows ----------------
      strongIn.p = p_gen "The pump delivers into the generator pressure";
      if idealVaporPort then
        vaporOut.p = p_gen;
      else
        m_r = k_vapor*(p_gen - vaporOut.p);
      end if;
      strongIn.m_flow + vaporOut.m_flow + weakOut.m_flow = 0 "Mass balance";
      m_ss*X6 = m_r*X3 + m_ws*X7 "Ammonia balance";

      // ---------------- Phase equilibrium at (p_gen, T_gen) ----------------
      T_gen_actual = TILMedia.VLEFluidFunctions.dewTemperature_pxi(
        vleFluidType, p_gen, xiOf(X3, xiIsWater));
      T_gen_actual = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(
        vleFluidType, p_gen, xiOf(X7, xiIsWater));
      h3 = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(
        vleFluidType, p_gen, xiOf(X3, xiIsWater));
      h7 = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(
        vleFluidType, p_gen, xiOf(X7, xiIsWater));

      // ---------------- Energy balance ----------------
      Q_flow_gen = m_r*h3 + m_ws*h7 - m_ss*h6;

      // ---------------- Outflowing streams ----------------
      vaporOut.h_outflow = h3;
      vaporOut.xi_outflow = xiOf(X3, xiIsWater);
      weakOut.h_outflow = h7 "Isenthalpic solution valve";
      weakOut.xi_outflow = xiOf(X7, xiIsWater);
      strongIn.h_outflow = h7 "Only used if the flow reverses";
      strongIn.xi_outflow = xiOf(X7, xiIsWater);

      // ---------------- State after the solution valve ----------------
      T8 = TILMedia.VLEFluidFunctions.temperature_phxi(
        vleFluidType, weakOut.p, h7, xiOf(X7, xiIsWater));
      Qu8 = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, weakOut.p, h7, xiOf(X7, xiIsWater));

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-80,70},{80,-50}}, lineColor={170,40,40},
              fillColor={255,200,190}, fillPattern=FillPattern.Solid, radius=6),
            Rectangle(extent={{-78,-10},{78,-48}}, pattern=LinePattern.None,
              fillColor={240,150,130}, fillPattern=FillPattern.Solid),
            Text(extent={{-76,56},{76,26}}, textColor={130,20,20}, textString="Generator"),
            Line(points={{-100,40},{-80,40}}, color={200,40,40}, thickness=0.5),
            Line(points={{80,40},{100,40}}, color={120,60,160}, thickness=0.5),
            Line(points={{0,-50},{0,-100}}, color={120,60,160}, thickness=0.5),
            Polygon(points={{-12,-63},{12,-63},{0,-75},{-12,-63}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Polygon(points={{-12,-87},{12,-87},{0,-75},{-12,-87}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Line(points={{100,-30},{82,-30}}, color={200,60,0}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            Ellipse(extent={{-96,52},{-84,64}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-96,52},{-84,64}}, textColor={0,0,0}, textString="3"),
            Ellipse(extent={{84,52},{96,64}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{84,52},{96,64}}, textColor={0,0,0}, textString="6"),
            Ellipse(extent={{12,-62},{24,-50}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{12,-62},{24,-50}}, textColor={0,0,0}, textString="7"),
            Ellipse(extent={{12,-100},{24,-88}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{12,-100},{24,-88}}, textColor={0,0,0}, textString="8"),
            Text(extent={{-150,110},{150,76}}, textColor={0,0,255}, textString="%name")}),
        Documentation(info="<html>
<p>Generator of a single-effect NH3-H2O cycle with the solution expansion valve
built in, steady state. Strong solution from the pump enters at strongIn,
saturated vapor (dew point) leaves at vaporOut, and saturated weak solution
(bubble point) leaves through the valve at weakOut, at the downstream pressure.</p>
<p>The pump sets the strong-solution flow. The generator gives the pump its
pressure (strongIn.p), splits the flow with the mass and ammonia balances, and
finds its pressure from the bubble point of the weak solution at T_gen.</p>
</html>"));
    end Generator;

    model Absorber "Absorber: refrigerant + weak solution in, saturated strong solution out"
      extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorberGeneratorTIL.Functions.xiOf;
      import AbsorberGeneratorTIL.Functions.XOf;

      // ---------------- Known quantities ----------------
      parameter Boolean specifyConcentration = false
        "= true: X_strong is known and the absorber pressure is calculated"
        annotation (Dialog(group="Known quantities"), choices(checkBox=true), Evaluate=true);
      parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature"
        annotation (Dialog(group="Known quantities"));
      parameter SI.AbsolutePressure P_abs = 400e3 "Absorber pressure"
        annotation (Dialog(group="Known quantities", enable=not specifyConcentration));
      parameter Real X_strong = 0.47 "Strong-solution NH3 mass fraction"
        annotation (Dialog(group="Known quantities", enable=specifyConcentration));

      // ---------------- Vapor connection ----------------
      parameter Boolean idealVaporPort = false
        "= true: vaporIn.p equals the absorber pressure (no vapor-line pressure drop)"
        annotation (Dialog(group="Vapor connection"), choices(checkBox=true), Evaluate=true);
      parameter SI.PressureDifference dp_vapor_nominal = 1e3
        "Vapor-line pressure drop at nominal flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));
      parameter SI.MassFlowRate m_flow_vapor_nominal = 0.05
        "Nominal refrigerant flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));

      // ---------------- Start values ----------------
      parameter SI.AbsolutePressure p_start = 400e3 "Absorber pressure"
        annotation (Dialog(tab="Initialization"));
      parameter Real X5_start = 0.47 "Strong-solution NH3 mass fraction"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_r_start = 0.05 "Refrigerant flow"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_ss_start = 0.33 "Strong-solution flow"
        annotation (Dialog(tab="Initialization"));

      // ---------------- Connectors ----------------
      AbsorberGeneratorTIL.Interfaces.VLEFluidPort vaporIn(p(start=p_start), m_flow(start=m_r_start))
        "Refrigerant from the evaporator (state 2)"
        annotation (Placement(transformation(extent={{-110,-30},{-90,-10}})));
      AbsorberGeneratorTIL.Interfaces.VLEFluidPort weakIn(p(start=p_start), m_flow(start=m_ss_start - m_r_start))
        "Weak solution from the generator (state 8)"
        annotation (Placement(transformation(extent={{-10,90},{10,110}})));
      AbsorberGeneratorTIL.Interfaces.VLEFluidPort strongOut(p(start=p_start), m_flow(start=-m_ss_start))
        "Strong solution to the pump (state 5)"
        annotation (Placement(transformation(extent={{90,-60},{110,-40}})));
      Modelica.Blocks.Interfaces.RealOutput Q_flow_abs(unit="W") "Absorber heat rejection"
        annotation (Placement(transformation(extent={{100,10},{120,30}})));

      // ---------------- Variables ----------------
      SI.AbsolutePressure p_abs(start=p_start) "Absorber pressure";
      Real X5(start=X5_start, min=0, max=1)
        "State 5: strong-solution NH3 mass fraction (bubble point)";
      SI.SpecificEnthalpy h5 "State 5: saturated liquid enthalpy";
      SI.SpecificEnthalpy h2 = inStream(vaporIn.h_outflow) "State 2: refrigerant enthalpy";
      Real xi2[vleFluidType.nc - 1] = inStream(vaporIn.xi_outflow)
        "State 2: TILMedia composition";
      Real X2 = XOf(xi2, xiIsWater) "State 2: refrigerant NH3 mass fraction";
      SI.SpecificEnthalpy h8 = inStream(weakIn.h_outflow) "State 8: weak-solution enthalpy";
      Real xi8[vleFluidType.nc - 1] = inStream(weakIn.xi_outflow)
        "State 8: TILMedia composition";
      Real X8 = XOf(xi8, xiIsWater) "State 8: weak-solution NH3 mass fraction";
      SI.MassFlowRate m_r = vaporIn.m_flow "Refrigerant in";
      SI.MassFlowRate m_ws = weakIn.m_flow "Weak solution in";
      SI.MassFlowRate m_ss = -strongOut.m_flow "Strong solution out (set by the pump)";
      SI.MassFlowRate massImbalance = m_r + m_ws - m_ss
        "In minus out; zero at steady state";
      SI.MassFlowRate ammoniaImbalance = m_r*X2 + m_ws*X8 - m_ss*X5
        "Ammonia in minus out; zero at steady state";
    protected
      final parameter Real k_vapor(unit="kg/(s.Pa)") = m_flow_vapor_nominal/dp_vapor_nominal
        "Vapor-line flow conductance";

    equation
      // ---------------- Known quantities ----------------
      if specifyConcentration then
        X5 = X_strong;
      else
        p_abs = P_abs;
      end if;

      // ---------------- Port pressures and flows ----------------
      weakIn.p = p_abs;
      strongOut.p = p_abs "The pump draws from the absorber pressure";
      if idealVaporPort then
        vaporIn.p = p_abs;
      else
        m_r = k_vapor*(vaporIn.p - p_abs);
      end if;

      // ---------------- Saturated strong solution at (p_abs, T_abs) ----------------
      T_abs = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(
        vleFluidType, p_abs, xiOf(X5, xiIsWater));
      h5 = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(
        vleFluidType, p_abs, xiOf(X5, xiIsWater));

      // ---------------- Energy balance ----------------
      Q_flow_abs = m_r*h2 + m_ws*h8 - m_ss*h5;

      // ---------------- Outflowing streams ----------------
      strongOut.h_outflow = h5;
      strongOut.xi_outflow = xiOf(X5, xiIsWater);
      vaporIn.h_outflow = h5 "Only used if the flow reverses";
      vaporIn.xi_outflow = xiOf(X5, xiIsWater);
      weakIn.h_outflow = h5 "Only used if the flow reverses";
      weakIn.xi_outflow = xiOf(X5, xiIsWater);

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-80,50},{80,-70}}, lineColor={30,80,160},
              fillColor={190,215,255}, fillPattern=FillPattern.Solid, radius=6),
            Rectangle(extent={{-78,-30},{78,-68}}, pattern=LinePattern.None,
              fillColor={140,180,240}, fillPattern=FillPattern.Solid),
            Text(extent={{-76,36},{76,6}}, textColor={20,50,130}, textString="Absorber"),
            Line(points={{0,100},{0,50}}, color={120,60,160}, thickness=0.5),
            Line(points={{-100,-20},{-80,-20}}, color={0,90,200}, thickness=0.5),
            Line(points={{80,-50},{100,-50}}, color={120,60,160}, thickness=0.5),
            Line(points={{82,20},{100,20}}, color={0,90,200}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            Ellipse(extent={{6,62},{18,74}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{6,62},{18,74}}, textColor={0,0,0}, textString="8"),
            Ellipse(extent={{-96,-8},{-84,4}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-96,-8},{-84,4}}, textColor={0,0,0}, textString="2"),
            Ellipse(extent={{84,-38},{96,-26}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{84,-38},{96,-26}}, textColor={0,0,0}, textString="5"),
            Text(extent={{-150,-76},{150,-110}}, textColor={0,0,255}, textString="%name")}),
        Documentation(info="<html>
<p>Absorber of a single-effect NH3-H2O cycle, steady state. Refrigerant enters at
vaporIn, weak solution at weakIn, and saturated strong solution (bubble point at
T_abs) leaves at strongOut toward the pump.</p>
<p>The absorber is the pressure reference of the low side: it fixes P_abs (or,
with specifyConcentration, the strong-solution concentration). Its mass and
ammonia balances are not imposed, because in a closed steady-state cycle they
repeat the generator balances. massImbalance and ammoniaImbalance report them;
both are zero at steady state.</p>
</html>"));
    end Absorber;
  end Components;

  // =====================================================================
  //  Examples
  // =====================================================================
  package Examples "Test cycle"

    model TestCycle
      "Complete cycle: AbsorberGenerator with simple stand-ins for the TIL pump, condenser, valve and evaporator"
      import SI = Modelica.Units.SI;
      import AbsorberGeneratorTIL.Functions.XOf;

      parameter Boolean xiIsWater = true "See PartialNH3H2O";

      // ---------------- Knowns ----------------
      parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
      parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
      parameter SI.AbsolutePressure P_abs = 400e3 "Absorber pressure";
      parameter SI.MassFlowRate m_strong = 0.33
        "Strong-solution flow set by the pump (use m_dot_abs from AbsorptionCycle_001)";
      parameter Real eta_p = 0.62 "Pump efficiency";
      parameter SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
      parameter SI.Temperature T_C = 273.15 + 5 "Evaporator temperature";
      parameter SI.TemperatureDifference DT_cond = 4 "Condenser approach";
      parameter SI.TemperatureDifference DT_evap = 3 "Evaporator approach";

      // ---------------- Valve sizing at the EES design point ----------------
      parameter SI.MassFlowRate m_r_design = 0.05 "Design refrigerant flow";
      parameter SI.AbsolutePressure P_gen_design = 1.6e6 "Design generator pressure";
      parameter SI.Density rho_valve_design = 590 "Liquid density at the valve inlet (estimate)";
      parameter SI.Area A_valve = m_r_design/sqrt(2*rho_valve_design*(P_gen_design - P_abs))
        "Valve flow area that passes the design flow at the design pressure difference";

      // ---------------- Components ----------------
      AbsorberGeneratorTIL.AbsorberGenerator absorberGenerator(
        xiIsWater=xiIsWater,
        T_gen=T_gen,
        T_abs=T_abs,
        P_abs=P_abs,
        m_ss_start=m_strong)
        annotation (Placement(transformation(extent={{20,-40},{100,40}})));
      AbsorberGeneratorTIL.Examples.StandIns.Pump pump(
        xiIsWater=xiIsWater,
        m_flow_set=m_strong,
        eta=eta_p)
        annotation (Placement(transformation(extent={{-20,-20},{20,20}},
              rotation=90, origin={140,0})));
      AbsorberGeneratorTIL.Examples.StandIns.Condenser condenser(
        xiIsWater=xiIsWater,
        T_out=T_amb + DT_cond)
        annotation (Placement(transformation(extent={{-10,4},{-50,44}})));
      AbsorberGeneratorTIL.Examples.StandIns.OrificeValve valve(
        xiIsWater=xiIsWater,
        A=A_valve)
        annotation (Placement(transformation(extent={{-20,-20},{20,20}},
              rotation=270, origin={-80,0})));
      AbsorberGeneratorTIL.Examples.StandIns.Evaporator evaporator(
        xiIsWater=xiIsWater,
        T_out=T_C - DT_evap)
        annotation (Placement(transformation(extent={{-50,-44},{-10,-4}})));

      // ---------------- State table (EES numbering) ----------------
      SI.Temperature T[8] "State temperatures";
      SI.AbsolutePressure P[8] "State pressures";
      SI.SpecificEnthalpy h[8] "State specific enthalpies";
      Real X[8] "State NH3 mass fractions";

      // ---------------- Results ----------------
      Real P_gen_kPa(unit="kPa") = absorberGenerator.P_high/1e3 "Generator pressure (result)";
      SI.MassFlowRate m_refrigerant = absorberGenerator.m_refrigerant "Refrigerant flow (result)";
      Real Q_gen_kW(unit="kW") = absorberGenerator.Q_flow_gen/1e3 "Generator heat input";
      Real Q_evap_kW(unit="kW") = evaporator.Q_flow/1e3 "Cooling capacity";
      Real Q_cond_kW(unit="kW") = condenser.Q_flow/1e3 "Condenser heat rejection";
      Real Q_abs_kW(unit="kW") = absorberGenerator.Q_flow_abs/1e3 "Absorber heat rejection";
      Real W_pump_kW(unit="kW") = pump.P_pump/1e3 "Pump power";
      Real COP = evaporator.Q_flow/absorberGenerator.Q_flow_gen "Coefficient of performance";
      Real balance_W(unit="W") = absorberGenerator.Q_flow_gen + evaporator.Q_flow + pump.P_pump
        - condenser.Q_flow - absorberGenerator.Q_flow_abs "Energy balance residual (should be ~0)";

      // ---------------- Displays (filled in after simulation) ----------------
      Modelica.Blocks.Interaction.Show.RealValue dispPgen(use_numberPort=false,
        number=P_gen_kPa, significantDigits=4)
        annotation (Placement(transformation(extent={{180,55},{240,85}})));
      Modelica.Blocks.Interaction.Show.RealValue dispMr(use_numberPort=false,
        number=m_refrigerant, significantDigits=3)
        annotation (Placement(transformation(extent={{180,35},{240,65}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQgen(use_numberPort=false,
        number=Q_gen_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,15},{240,45}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQevap(use_numberPort=false,
        number=Q_evap_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-5},{240,25}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQcond(use_numberPort=false,
        number=Q_cond_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-25},{240,5}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQabs(use_numberPort=false,
        number=Q_abs_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-45},{240,-15}})));
      Modelica.Blocks.Interaction.Show.RealValue dispWpump(use_numberPort=false,
        number=W_pump_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-65},{240,-35}})));
      Modelica.Blocks.Interaction.Show.RealValue dispCOP(use_numberPort=false,
        number=COP, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-85},{240,-55}})));

    equation
      // ---------------- Refrigerant loop ----------------
      connect(absorberGenerator.vaporOut, condenser.portA)
        annotation (Line(points={{20,24},{-10,24}}, color={200,40,40}, thickness=0.5));
      connect(condenser.portB, valve.portA)
        annotation (Line(points={{-50,24},{-80,24},{-80,20}}, color={200,40,40}, thickness=0.5));
      connect(valve.portB, evaporator.portA)
        annotation (Line(points={{-80,-20},{-80,-24},{-50,-24}}, color={0,90,200}, thickness=0.5));
      connect(evaporator.portB, absorberGenerator.vaporIn)
        annotation (Line(points={{-10,-24},{20,-24}}, color={0,90,200}, thickness=0.5));

      // ---------------- Solution loop (pump) ----------------
      connect(absorberGenerator.strongOut, pump.portA)
        annotation (Line(points={{100,-24},{140,-24},{140,-20}}, color={120,60,160}, thickness=0.5));
      connect(pump.portB, absorberGenerator.strongIn)
        annotation (Line(points={{140,20},{140,24},{100,24}}, color={120,60,160}, thickness=0.5));

      // ---------------- State table ----------------
      // 1: valve outlet / evaporator inlet
      T[1] = valve.T_out;
      P[1] = valve.portB.p;
      h[1] = valve.portB.h_outflow;
      X[1] = XOf(valve.portB.xi_outflow, xiIsWater);
      // 2: evaporator outlet / absorber inlet
      T[2] = evaporator.T_out;
      P[2] = evaporator.portB.p;
      h[2] = evaporator.portB.h_outflow;
      X[2] = XOf(evaporator.portB.xi_outflow, xiIsWater);
      // 3: generator vapor
      T[3] = absorberGenerator.generator.T_gen_actual;
      P[3] = absorberGenerator.generator.p_gen;
      h[3] = absorberGenerator.generator.h3;
      X[3] = absorberGenerator.generator.X3;
      // 4: condenser outlet / valve inlet
      T[4] = condenser.T_out;
      P[4] = condenser.portB.p;
      h[4] = condenser.portB.h_outflow;
      X[4] = XOf(condenser.portB.xi_outflow, xiIsWater);
      // 5: absorber outlet / pump inlet
      T[5] = absorberGenerator.absorber.T_abs;
      P[5] = absorberGenerator.absorber.p_abs;
      h[5] = absorberGenerator.absorber.h5;
      X[5] = absorberGenerator.absorber.X5;
      // 6: pump outlet / generator inlet
      T[6] = pump.T_out;
      P[6] = pump.portB.p;
      h[6] = pump.portB.h_outflow;
      X[6] = XOf(pump.portB.xi_outflow, xiIsWater);
      // 7: generator liquid outlet
      T[7] = absorberGenerator.generator.T_gen_actual;
      P[7] = absorberGenerator.generator.p_gen;
      h[7] = absorberGenerator.generator.h7;
      X[7] = absorberGenerator.generator.X7;
      // 8: after the solution valve / absorber inlet
      T[8] = absorberGenerator.generator.T8;
      P[8] = absorberGenerator.absorber.p_abs;
      h[8] = absorberGenerator.generator.h7;
      X[8] = absorberGenerator.generator.X7;

      annotation (
        experiment(StopTime=1),
        Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-110,-95},{255,100}}),
          graphics={
            // pressure zones
            Rectangle(extent={{-108,0},{165,82}}, pattern=LinePattern.None,
              fillColor={255,243,238}, fillPattern=FillPattern.Solid),
            Rectangle(extent={{-108,-90},{165,0}}, pattern=LinePattern.None,
              fillColor={236,244,255}, fillPattern=FillPattern.Solid),
            Line(points={{-108,0},{165,0}}, color={150,150,150}, pattern=LinePattern.Dash),
            Text(extent={{-106,70},{-30,78}}, textColor={170,40,40},
              horizontalAlignment=TextAlignment.Left, textString="HIGH PRESSURE (result)"),
            Text(extent={{-106,-78},{-30,-70}}, textColor={20,60,150},
              horizontalAlignment=TextAlignment.Left, textString="LOW PRESSURE (P_abs)"),
            Text(extent={{-106,86},{165,98}}, textColor={0,0,0},
              horizontalAlignment=TextAlignment.Left,
              textString="NH3-H2O absorption cycle: AbsorberGenerator + TIL-style components"),
            // heat flows
            Line(points={{-30,48},{-30,62}}, color={200,60,0}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=4),
            Text(extent={{-26,54},{0,62}}, textColor={200,60,0},
              horizontalAlignment=TextAlignment.Left, textString="Q_cond"),
            Line(points={{-30,-62},{-30,-48}}, color={0,90,200}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=4),
            Text(extent={{-26,-62},{0,-54}}, textColor={0,90,200},
              horizontalAlignment=TextAlignment.Left, textString="Q_evap"),
            // state labels 1-6 (7 and 8 are inside the AbsorberGenerator icon)
            Ellipse(extent={{-70,-35},{-60,-25}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-70,-35},{-60,-25}}, textColor={0,0,0}, textString="1"),
            Ellipse(extent={{0,-35},{10,-25}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{0,-35},{10,-25}}, textColor={0,0,0}, textString="2"),
            Ellipse(extent={{0,25},{10,35}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{0,25},{10,35}}, textColor={0,0,0}, textString="3"),
            Ellipse(extent={{-70,25},{-60,35}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-70,25},{-60,35}}, textColor={0,0,0}, textString="4"),
            Ellipse(extent={{115,-35},{125,-25}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{115,-35},{125,-25}}, textColor={0,0,0}, textString="5"),
            Ellipse(extent={{115,25},{125,35}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{115,25},{125,35}}, textColor={0,0,0}, textString="6"),
            // results panel
            Rectangle(extent={{170,-90},{250,98}}, lineColor={120,120,120},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid, radius=3),
            Text(extent={{172,88},{248,96}}, textColor={0,0,0},
              textString="Results (after simulation)")}),
        Documentation(info="<html>
<p>Full cycle with the AbsorberGenerator and simple stand-ins for the pump, condenser,
throttling valve and evaporator. Once the ports use the TIL connector, the stand-ins
can be replaced one at a time with TIL components.</p>
<p><b>Knowns:</b> T_gen, T_abs, P_abs (AbsorberGenerator), strong-solution flow and
efficiency (pump), flow area (valve), outlet temperatures (condenser, evaporator).
<b>Results:</b> generator pressure, refrigerant flow, all heat flows and the COP.</p>
<p>The valve area is sized so the EES design point (0.05 kg/s at 1600/400 kPa)
is reproduced when m_strong matches m_dot_abs from AbsorptionCycle_001.</p>
</html>"));
    end TestCycle;

    package StandIns "Simple pump, condenser, valve and evaporator (stand-ins for TIL components)"

      partial model PartialTwoPort "Two-port, no storage"
        extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
        parameter Modelica.Units.SI.AbsolutePressure pA_start = 1e6 "Inlet pressure"
          annotation (Dialog(tab="Initialization"));
        parameter Modelica.Units.SI.AbsolutePressure pB_start = 1e6 "Outlet pressure"
          annotation (Dialog(tab="Initialization"));
        AbsorberGeneratorTIL.Interfaces.VLEFluidPort portA(p(start=pA_start))
          "Inlet"
          annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
        AbsorberGeneratorTIL.Interfaces.VLEFluidPort portB(p(start=pB_start))
          "Outlet"
          annotation (Placement(transformation(extent={{90,-10},{110,10}})));
        Modelica.Units.SI.SpecificEnthalpy h_in = inStream(portA.h_outflow) "Inlet enthalpy";
        Real xi_in[vleFluidType.nc - 1] = inStream(portA.xi_outflow)
          "Inlet TILMedia composition";
        Real X_in = AbsorberGeneratorTIL.Functions.XOf(xi_in, xiIsWater)
          "Inlet NH3 mass fraction";
        Modelica.Units.SI.MassFlowRate m_flow = portA.m_flow "Mass flow rate";
      equation
        portA.m_flow + portB.m_flow = 0;
        portB.xi_outflow = xi_in;
        portA.h_outflow = inStream(portB.h_outflow);
        portA.xi_outflow = inStream(portB.xi_outflow);
      end PartialTwoPort;

      model Pump "Pump with fixed mass flow (stand-in for the TIL pump)"
        extends PartialTwoPort(pA_start=400e3, pB_start=1.6e6);
        parameter Modelica.Units.SI.MassFlowRate m_flow_set = 0.33 "Mass flow rate";
        parameter Real eta = 0.62 "Pump efficiency";
        Modelica.Units.SI.Density rho_in "Inlet density (saturated liquid)";
        Modelica.Units.SI.Temperature T_out "Outlet temperature";
        Modelica.Blocks.Interfaces.RealOutput P_pump(unit="W") "Pump power"
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
                rotation=90, origin={0,110})));
      equation
        portA.m_flow = m_flow_set;
        rho_in = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, portA.p, xi_in);
        portB.h_outflow = h_in + (portB.p - portA.p)/(rho_in*eta);
        P_pump = m_flow*(portB.h_outflow - h_in);
        T_out = TILMedia.VLEFluidFunctions.temperature_phxi(
          vleFluidType, portB.p, portB.h_outflow, xi_in);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Line(points={{-100,0},{-60,0}}, color={120,60,160}, thickness=0.5),
              Line(points={{60,0},{100,0}}, color={120,60,160}, thickness=0.5),
              Ellipse(extent={{-60,60},{60,-60}}, lineColor={0,0,0},
                fillColor={255,255,255}, fillPattern=FillPattern.Solid),
              Polygon(points={{-28,40},{52,0},{-28,-40},{-28,40}}, lineColor={0,0,0},
                fillColor={120,60,160}, fillPattern=FillPattern.Solid),
              Text(extent={{-150,-66},{150,-100}}, textColor={0,0,255}, textString="%name")}));
      end Pump;

      model Condenser "Condenser with fixed outlet temperature (stand-in for a TIL heat exchanger)"
        extends PartialTwoPort(pA_start=1.6e6, pB_start=1.6e6);
        parameter Modelica.Units.SI.Temperature T_out = 273.15 + 29 "Outlet temperature";
        Real Qu_out "Outlet vapor quality";
        Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Heat rejected"
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
                rotation=90, origin={0,110})));
      equation
        portB.p = portA.p;
        portB.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
          vleFluidType, portA.p, T_out, xi_in);
        Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
          vleFluidType, portA.p, portB.h_outflow, xi_in);
        Q_flow = m_flow*(h_in - portB.h_outflow);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Rectangle(extent={{-80,40},{80,-40}}, lineColor={170,40,40},
                fillColor={255,225,215}, fillPattern=FillPattern.Solid),
              Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
                {30,20},{50,-20},{60,0},{100,0}}, color={200,40,40}, thickness=0.5),
              Text(extent={{-80,-44},{80,-70}}, textColor={130,20,20}, textString="Condenser"),
              Text(extent={{-150,90},{150,56}}, textColor={0,0,255}, textString="%name")}));
      end Condenser;

      model OrificeValve "Orifice throttling valve (stand-in for a TIL valve)"
        extends PartialTwoPort(pA_start=1.6e6, pB_start=400e3);
        parameter Modelica.Units.SI.Area A = 1.3e-6 "Effective flow area";
        parameter Modelica.Units.SI.PressureDifference dp_small = 1e3
          "Smoothing range around zero pressure difference";
        Modelica.Units.SI.Density rho_in "Inlet density (saturated-liquid estimate)";
        Modelica.Units.SI.Temperature T_out "Outlet temperature";
        Real Qu_out "Outlet vapor quality";
      equation
        rho_in = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, portA.p, xi_in);
        portA.m_flow = A*sqrt(2*rho_in)*Modelica.Fluid.Utilities.regRoot(portA.p - portB.p, dp_small);
        portB.h_outflow = h_in;
        T_out = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, portB.p, h_in, xi_in);
        Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, portB.p, h_in, xi_in);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Polygon(points={{-80,40},{-80,-40},{0,0},{-80,40}}, lineColor={0,0,0},
                fillColor={255,255,255}, fillPattern=FillPattern.Solid),
              Polygon(points={{80,40},{80,-40},{0,0},{80,40}}, lineColor={0,0,0},
                fillColor={255,255,255}, fillPattern=FillPattern.Solid),
              Line(points={{-100,0},{-80,0}}, color={200,40,40}, thickness=0.5),
              Line(points={{80,0},{100,0}}, color={0,90,200}, thickness=0.5),
              Text(extent={{-150,-50},{150,-90}}, textColor={0,0,255}, textString="%name")}));
      end OrificeValve;

      model Evaporator "Evaporator with fixed outlet temperature (stand-in for a TIL heat exchanger)"
        extends PartialTwoPort(pA_start=400e3, pB_start=400e3);
        parameter Modelica.Units.SI.Temperature T_out = 273.15 + 2 "Outlet temperature";
        Real Qu_out "Outlet vapor quality";
        Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Cooling capacity"
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
                rotation=270, origin={0,-110})));
      equation
        portB.p = portA.p;
        portB.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
          vleFluidType, portA.p, T_out, xi_in);
        Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
          vleFluidType, portA.p, portB.h_outflow, xi_in);
        Q_flow = m_flow*(portB.h_outflow - h_in);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Rectangle(extent={{-80,40},{80,-40}}, lineColor={30,80,160},
                fillColor={215,235,255}, fillPattern=FillPattern.Solid),
              Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
                {30,20},{50,-20},{60,0},{100,0}}, color={0,90,200}, thickness=0.5),
              Text(extent={{-80,70},{80,44}}, textColor={20,50,130}, textString="Evaporator"),
              Text(extent={{-150,-56},{150,-90}}, textColor={0,0,255}, textString="%name")}));
      end Evaporator;
    end StandIns;
  end Examples;

  // =====================================================================
  //  Interfaces and functions
  // =====================================================================
  package Interfaces "Connector and partial models"
    connector VLEFluidPort
      "NH3-H2O fluid port with the same p, m_flow, h_outflow and xi_outflow as TIL's VLEFluidPort"
      Modelica.Units.SI.AbsolutePressure p "Pressure";
      flow Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate into the component";
      stream Modelica.Units.SI.SpecificEnthalpy h_outflow
        "Specific enthalpy close to the port if the fluid leaves the component";
      stream Modelica.Units.SI.MassFraction xi_outflow[1]
        "TILMedia composition (water mass fraction) close to the port if the fluid leaves";
      annotation (Icon(graphics={Ellipse(extent={{-100,100},{100,-100}},
              lineColor={0,100,0}, fillColor={153,204,0}, fillPattern=FillPattern.Solid)}),
        Documentation(info="<html>
<p>Local stand-in for TIL.Connectors.VLEFluidPort. TIL's connector carries two
more variables, which the components in this package do not set yet; once those
are known, the ports switch back to the TIL connector.</p>
</html>"));
    end VLEFluidPort;

    partial model PartialNH3H2O "Fluid definition shared by all components"
      replaceable parameter TILMedia.VLEFluidTypes.TILMedia_WaterAmmonia_nc2 vleFluidType
        constrainedby TILMedia.VLEFluidTypes.BaseVLEFluid "NH3-H2O working fluid"
        annotation (choicesAllMatching=true, Dialog(tab="Fluid"));
      parameter Boolean xiIsWater = true
        "= true: TILMedia xi[1] is the water mass fraction (xi = 1 - X_NH3)"
        annotation (Dialog(tab="Fluid"), choices(checkBox=true));
    equation
      assert(vleFluidType.nc == 2,
        "AbsorberGeneratorTIL needs a two-component fluid such as TILMedia_WaterAmmonia_nc2");
    end PartialNH3H2O;
  end Interfaces;

  package Functions "Composition helpers"
    function xiOf "TILMedia composition vector from NH3 mass fraction"
      input Real X "NH3 mass fraction";
      input Boolean xiIsWater = true "true: xi[1] is the water mass fraction";
      output Real xi[1] "TILMedia composition vector";
    algorithm
      xi := {if xiIsWater then 1 - X else X};
      annotation (Inline=true);
    end xiOf;

    function XOf "NH3 mass fraction from TILMedia composition vector"
      input Real xi[:] "TILMedia composition vector";
      input Boolean xiIsWater = true "true: xi[1] is the water mass fraction";
      output Real X "NH3 mass fraction";
    algorithm
      X := if xiIsWater then 1 - xi[1] else xi[1];
      annotation (Inline=true);
    end XOf;
  end Functions;

  annotation (uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")),
    Documentation(info="<html>
<p>Steady-state NH3-H2O generator/absorber. The ports (Interfaces.VLEFluidPort) carry
the same variables as TIL's VLEFluidPort except two that TIL adds; switching to the TIL
connector needs those two handled.</p>
<ul>
<li><b>AbsorberGenerator</b>: the combined component (main item).</li>
<li><b>Components.Generator</b>, <b>Components.Absorber</b>: the two halves, usable separately.</li>
<li><b>Examples.TestCycle</b>: complete cycle with stand-ins for the TIL pump, condenser, valve and evaporator.</li>
</ul>
</html>"));
end AbsorberGeneratorTIL;
