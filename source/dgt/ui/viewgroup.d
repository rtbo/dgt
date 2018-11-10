module dgt.ui.viewgroup;

import dgt.ui.view;

class ViewGroup : View
{
    this() {}

    public override void appendView(View view)
    {
        super.appendView(view);
    }

    public override void prependView(View view)
    {
        super.prependView(view);
    }

    public override void insertViewBefore(View view, View child)
    {
        super.insertViewBefore(view, child);
    }

    public override void removeView(View view)
    {
        super.removeView(view);
    }
}
