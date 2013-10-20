package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.animation.client.Animation
import com.google.gwt.core.client.Scheduler
import com.google.gwt.event.dom.client.MouseDownEvent
import com.google.gwt.event.dom.client.TouchStartEvent
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.ui.HorizontalPanel
import com.google.gwt.user.client.ui.SimplePanel
import com.google.gwt.user.client.ui.VerticalPanel
import com.google.gwt.user.client.ui.Widget
import java.util.List

abstract class AnimatedCarouselWidget extends CarouselWidgetBase {

	val public static STYLE_TRANSITIONED = "transitioned"
	val static STYLE_CHILD_WRAPPER = "childwrapper"

	val protected EaseOutAnimation anim = [onUpdate]
	val protected Timer runTimer = [|onAnimationEnd]

	int prependedChildren

	protected int width = 1
	protected int height = 1

	@Property boolean animationFallback
	int animTargetPosition
	int animStartPosition

	@Property CarouselLoadMode loadMode
	int transitionDuration = 1000

	override setWidgets(List<Widget> _widgets) {
		if (!_widgets.isEmpty) {
			val currentWidget = if(childPanel.widgetCount > index) getWrapper(index)
			var currentWidgetIndex = if(currentWidget != null) widgets.indexOf(currentWidget.widget) else 0
			currentWidgetIndex = Math::max(currentWidgetIndex, 0)
			currentWidgetIndex = Math::min(currentWidgetIndex, _widgets.size - 1)

			widgets = newArrayList
			for (w : _widgets) {
				widgets += w ?: new PlaceHolder
			}

			updatePaddings

			for (i : 0 ..< widgets.size) {
				getWrapper(index + i - currentWidgetIndex).widget = widgets.get(i)
			}

			if (_widgets.contains(null)) {
				listeners.forEach[requestWidgets(widgets.indexOf(selectedWidget))]
			}

			onUpdate(0)
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

	def protected getCurrentMargin() {
		prependedChildren * -measure
	}

	override protected scrollToPanelIndex(int _index) {
		Scheduler::get().scheduleDeferred(
			[ |
				if (widgets.size > 1) {
					index = _index

					updatePaddings

					addStyleName(STYLE_TRANSITIONED)

					animStartPosition = childPanelCurrentPosition

					animTargetPosition = index * -measure - currentMargin
					if (!animationFallback) {
						setChildPanelPosition(animTargetPosition)
					}

					anim.run(transitionDuration)
					runTimer.schedule(transitionDuration)
					tabKeyEnabled = false
					unhideAllWidgets
				}
			])
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
		if (widgets.size > 1) {
			if (animationFallback) {
				val newPosition = animTargetPosition - (animTargetPosition - animStartPosition) * (1.0 - progress)
				setChildPanelPosition(newPosition)
			}

			val repositionTreshold = widgets.size / 2 * measure

			for (w : widgets) {
				val wrapper = w.parent as SimplePanel
				var wrapperPosition = getPositionRelativeToCarousel(wrapper)
				if (Math::abs(wrapperPosition) > repositionTreshold) {
					val newIndex = childPanel.getWidgetIndex(wrapper) -
						widgets.size * Math::signum(wrapperPosition) as int
					getWrapper(newIndex).widget = wrapper?.widget
				}
			}
		}
	}

	def protected onAnimationEnd() {
		setChildPanelPosition(animTargetPosition)

		val selectedIndex = widgets.indexOf(selectedWidget)
		if (widgets.exists[class == PlaceHolder] &&
			(loadMode == CarouselLoadMode::SMART || selectedWidget.class == PlaceHolder)) {
			listeners.forEach[requestWidgets(selectedIndex)]
		}
		listeners.forEach[widgetSelected(selectedIndex)]
		minimizePaddings
		tabKeyEnabled = true

		hideNonVisibleWidgets
	}

	def setCarouselSize(int width, int height) {
		this.width = Math::max(width, 1)
		this.height = Math::max(height, 1)

		removeStyleName(STYLE_TRANSITIONED)

		childPanel.forEach[setPixelSize(width, height)]

		setChildPanelPosition(index * -measure - currentMargin)
		updateChildPanelMargin

		onUpdate(0)

		addStyleName(STYLE_TRANSITIONED)
	}

	def setTransitionDuration(int duration) {
		transitionDuration = duration
		val style = childPanel.element.style
		val value = duration + "ms"
		val propertyName = "transitionDuration"
		style.setProperty(propertyName, value)
		for (browserPrefix : #["webkit", "Moz", "ms", "O"]) {
			style.setProperty(browserPrefix + propertyName.toFirstUpper, value)
		}
	}

	def protected int getPositionRelativeToCarousel(Widget widget)

	def protected int getChildPanelCurrentPosition()

	def protected int getMeasure()

	def protected void setChildPanelPosition(double position)

	def protected void updateChildPanelMargin()
}

abstract class EaseOutAnimation extends Animation {
	override protected interpolate(double progress) {
		if(progress < 0.5) progress else super.interpolate(progress)
	}
}
