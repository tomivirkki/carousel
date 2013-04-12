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

	int width = 1
	int height = 1

	@Property boolean animationFallback
	int animTargetPosition
	int animStartPosition

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

		onUpdate(0)
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

	def protected getCurrentMargin() {
		prependedChildren * -measure
	}

	override protected scrollToPanelIndex(int _index) {
		if (widgets.size > 1){
			index = _index
	
			updatePaddings
	
			addStyleName(STYLE_TRANSITIONED)
	
			animStartPosition = if (horizontal) {
				childPanel.element.absoluteLeft - currentMargin - element.offsetLeft
			} else {
				childPanel.element.absoluteTop - currentMargin - element.offsetTop
			}
	
			animTargetPosition = index * -measure - currentMargin
			if (!animationFallback) {
				setChildPanelPosition(animTargetPosition)
			}
	
			anim.run(transitionDuration)
			runTimer.schedule(transitionDuration)
		}
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
			updateChildPanelMargin
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
			updateChildPanelMargin
		}
	}

	def private onUpdate(double progress) {
		if (animationFallback && progress < 1.0) {
			val newPosition = animTargetPosition - (animTargetPosition - animStartPosition) * (1.0 - progress)
			setChildPanelPosition(newPosition)
		}

		for (w : widgets) {
			val wrapper = w.parent as SimplePanel
			val wrapperPosition = if(horizontal) wrapper.element.absoluteLeft else wrapper.element.absoluteTop
			if (Math::abs(wrapperPosition) > repositionTreshold) {
				val newIndex = childPanel.getWidgetIndex(wrapper) -
					widgets.size * Math::signum(wrapperPosition) as int
				getWrapper(newIndex).widget = wrapper?.widget
			}
		}
	}

	def protected onAnimationEnd() {
		if (!animationFallback) {
			setChildPanelPosition(animTargetPosition)
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

		setChildPanelPosition(index * -measure - currentMargin)
		updateChildPanelMargin

		repositionTreshold = widgets.size / 2 * measure
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
	}

	def protected int getMeasure() {
		if(horizontal) width else height
	}

	def protected setChildPanelPosition(double position) {
		childPanel.element.style => [
			if (horizontal) {
				setLeft(position, PX)
			} else {
				setTop(position, PX)
			}
		]
	}

	def protected updateChildPanelMargin() {
		childPanel.element.style => [
			if (horizontal) {
				setMarginLeft(currentMargin, PX)
			} else {
				setMarginTop(currentMargin, PX)
			}
		]
	}
}
