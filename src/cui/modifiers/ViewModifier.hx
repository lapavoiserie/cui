package cui.modifiers;

import cui.render.Color;
import cui.render.BorderStyle;
import cui.layout.Edge;

enum Alignment {
    Left;
    Center;
    Right;
}

enum SizePolicy {
    Fixed(value:Int);
    Fill(weight:Int);
    Fit;
}

enum ViewModifier {
    // Text styling
    ForegroundColor(color:Color);
    BackgroundColor(color:Color);
    Bold;
    Dim;
    Italic;
    Underline;
    Strikethrough;
    Inverse;

    // Layout
    PaddingAll(value:Int);
    PaddingEdges(top:Int, right:Int, bottom:Int, left:Int);
    WidthPolicy(policy:SizePolicy);
    HeightPolicy(policy:SizePolicy);
    ContentAlignment(align:Alignment);

    // Border
    Border(style:BorderStyle);

    /** Children are cut at this view's edge. `nui.Modifiers.CLIP`. **/
    Clip;

    // Visibility
    Hidden;
}
