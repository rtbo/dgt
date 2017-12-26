module dgt.ui.view;

import dgt.core.geometry;
import dgt.scene.node;
import dgt.ui.layout;

class View : Node {

    /// The padding of the view, that is, how much empty space is required
    /// around the content.
    /// Padding is always within the view's rect.
    @property FPadding padding() const
    {
        return _padding;
    }

    /// ditto
    @property void padding(in FPadding padding)
    {
        _padding = padding;
    }

    /// Ask this view to measure itself by assigning the measurement property.
    void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = FSize(widthSpec.size, heightSpec.size);
    }

    /// Size set by the view during measure phase
    final @property FSize measurement() const
    {
        return _measurement;
    }

    /// ditto
    final protected @property void measurement(in FSize sz)
    {
        _measurement = sz;
    }

    /// Ask the view to layout itself in the given rect
    /// The default implementation assign the rect property.
    void layout(in FRect rect)
    {
        this.rect = rect;
    }

    /// The 'logical' rect of the view.
    /// This is expressed in parent coordinates, and do not take into account
    /// the transform applied to this view.
    /// Actual bounds may differ due to use of borders, shadows or transform.
    /// This rect is the one used in layout calculations.
    final @property FRect rect()
    {
        return _rect;
    }
    /// ditto
    final @property void rect(in FRect rect)
    {
        if (rect != _rect) {
            _rect = rect;
            dirtyBounds();
        }
    }

    @property Layout.Params layoutParams()
    {
        return _layoutParams;
    }
    @property void layoutParams(Layout.Params params)
    {
        _layoutParams = params;
    }

    // layout
    private FPadding        _padding;
    private FSize           _measurement;
    private FRect           _rect;
    private Layout.Params   _layoutParams;
}
