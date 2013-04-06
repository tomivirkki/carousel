package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.animation.client.Animation
import com.google.gwt.event.dom.client.MouseDownEvent
import com.google.gwt.event.dom.client.TouchStartEvent
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.ui.HorizontalPanel
import com.google.gwt.user.client.ui.VerticalPanel
import com.google.gwt.user.client.ui.SimplePanel
import com.google.gwt.user.client.ui.Widget
import java.util.List

import static com.google.gwt.dom.client.Style$Unit.*

abstract class AnimatedCarouselWidget extends CarouselWidgetBase {

	val public static STYLE_TRANSITIONED = "transitioned"
	val static STYLE_CHILD_WRAPPER = "childwrapper"

	val protected Animation anim = [onUpdate]
	val protected Timer runTimer = [|onAnimationEnd]

	int prependedChildren
	int repositionTreshold

	protected int width = 1
	protected int height = 1

	@Property boolean animationFallback
	int animTargetLeft
	int animStartLeft

	@Property CarouselLoadMode loadMode
	int transitionDuration = 1000

	override setWidgets(List<Widget> _widgets) {
		val currentWidget = if(childPanel.widgetCount > index) getWrapper(index)
		val currentWidgetIndex = if(currentWidget != null) widgets.indexOf(currentWidget.widget) else 0

		widgets = newArrayList
		for (w : _widgets) {
			widgets.add(if(w == null) new PlaceHolder else w)
		}

		updatePaddings

		for (i : 0 ..< widgets.size) {
			getWrapper(index + i - currentWidgetIndex).widget = widgets.get(i)
		}

		if (_widgets.contains(null) && loadMode == CarouselLoadMode::SMART) {
			listeners.forEach[requestWidgets(widgets.indexOf(selectedWidget))]
		}

		//TODO: See Carousel.java. This is a temporary workaround
		if (selectedWidget.class == typeof(PlaceHolder)) {
			listeners.forEach[requestWidgets(widgets.indexOf(selectedWidget))]
		}

	}

	def private wrap(Widget widget) {
		new SimplePanel(widget) => [
			styleName = STYLE_CHILD_WRAPPER
			val panel = it
			addDomHandler([index = childPanel.getWidgetIndex(panel)], TouchStartEvent::type)
			addDomHandler([index = childPanel.getWidgetIndex(panel)], MouseDownEvent::type)
			setPixelSize(width, height)
		]
	}

	def protected getCurrentMarginLeft() {
		prependedChildren * -width
	}

	override protected scrollToPanelIndex(int _index) {
		index = _index

		updatePaddings

		addStyleName(STYLE_TRANSITIONED)

		animStartLeft = childPanel.element.absoluteLeft - currentMarginLeft - element.offsetLeft
		animTargetLeft = index * -width - currentMarginLeft
		if (!animationFallback) {
			childPanel.element.style.setLeft(animTargetLeft, PX)
		}

		anim.run(transitionDuration)
		runTimer.schedule(transitionDuration)
	}

	def private updatePaddings() {
		while (childPanel.widgetCount < index + widgets.size) {
			childPanel.add(wrap(null))
		}

		while (index <= widgets.size) {
			val panel = childPanel
			switch (panel) {
				HorizontalPanel: panel.insert(wrap(null), 0)
				VerticalPanel: panel.insert(wrap(null), 0)
			}

			index = index + 1
			prependedChildren = prependedChildren + 1
			childPanel.element.style.setMarginLeft(currentMarginLeft, PX)
		}
	}

	def private minimizePaddings() {
		while (childPanel.widgetCount > index + widgets.size * 3) {
			childPanel.remove(childPanel.size - 1)
		}

		while (index > widgets.size * 3) {
			childPanel.remove(0)
			index = index - 1
			prependedChildren = prependedChildren - 1
			childPanel.element.style.setMarginLeft(currentMarginLeft, PX)
		}
	}

	def private onUpdate(double progress) {
		if (animationFallback && progress < 1.0) {
			val newLeft = animTargetLeft - (animTargetLeft - animStartLeft) * (1.0 - progress)
			childPanel.element.style.setLeft(newLeft, PX)
		}

		for (w : widgets) {
			val wrapper = w.parent as SimplePanel
			if (Math::abs(wrapper.element.absoluteLeft) > repositionTreshold) {
				val newIndex = childPanel.getWidgetIndex(wrapper) -
					widgets.size * Math::signum(wrapper.element.absoluteLeft) as int
				getWrapper(newIndex).widget = wrapper?.widget
			}
		}
	}

	def protected onAnimationEnd() {
		if (animationFallback) {
			childPanel.element.style.setLeft(animTargetLeft, PX)
		}
		if (widgets.exists[class == typeof(PlaceHolder)] &&
			(loadMode == CarouselLoadMode::SMART || selectedWidget.class == typeof(PlaceHolder))) {
			listeners.forEach[requestWidgets(widgets.indexOf(selectedWidget))]
		}
		listeners.forEach[widgetSelected(widgets.indexOf(selectedWidget))]
		minimizePaddings
	}

	def setCarouselSize(int width, int height) {
		this.width = Math::max(width, 1)
		this.height = Math::max(height, 1)

		removeStyleName(STYLE_TRANSITIONED)

		childPanel.forEach[setPixelSize(width, height)]

		childPanel.element.style => [
			setLeft(index * -width - currentMarginLeft, PX)
			setMarginLeft(currentMarginLeft, PX)
		]

		repositionTreshold = widgets.size / 2 * width
		onUpdate(0)

		addStyleName(STYLE_TRANSITIONED)
	}

	def setTransitionDuration(int duration) {
		transitionDuration = duration
		val style = childPanel.element.style
		val value = duration + "ms"
		val propertyName = "transitionDuration"
		style.setProperty(propertyName, value)
		for (browserPrefix : newArrayList("webkit", "Moz", "ms", "O")) {
			style.setProperty(browserPrefix + propertyName.toFirstUpper, value)
		}
	} //	def protected int getMeasure()
//	
//	def protected String getMeasureProperty()
}
