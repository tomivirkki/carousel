package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.animation.client.Animation
import com.google.gwt.event.dom.client.KeyCodes
import com.google.gwt.event.dom.client.MouseDownEvent
import com.google.gwt.event.dom.client.MouseWheelEvent
import com.google.gwt.event.dom.client.TouchStartEvent
import com.google.gwt.event.shared.HandlerRegistration
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.Timer
import com.google.gwt.user.client.ui.Button
import com.google.gwt.user.client.ui.FlowPanel
import com.google.gwt.user.client.ui.FocusPanel
import com.google.gwt.user.client.ui.HorizontalPanel
import com.google.gwt.user.client.ui.SimplePanel
import com.google.gwt.user.client.ui.Widget
import java.util.List

import static com.google.gwt.dom.client.Style$Unit.*

class CarouselWidget extends FocusPanel {

	val static STYLE_NAME = "carousel"
	val static STYLE_CAROUSEL_PANEL = "carouselpanel"
	val static STYLE_TRANSITIONED = "transitioned"
	val static STYLE_CHILD_PANEL_WRAPPER = "childpanelwrapper"
	val static STYLE_CHILD_PANEL = "childpanel"
	val static STYLE_CHILD_WRAPPER = "childwrapper"
	val static STYLE_CAROUSEL_BUTTON = "carouselbutton"
	val static STYLE_LEFT_BUTTON = "leftbutton"
	val static STYLE_RIGHT_BUTTON = "rightbutton"

	List<Widget> widgets = newArrayList
	List<CarouselWidgetListener> listeners = newArrayList

	val childPanel = new HorizontalPanel => [styleName = STYLE_CHILD_PANEL]

	val Animation anim = [onUpdate]
	val Timer runTimer = [|onAnimationEnd]

	int index
	int prependedChildren
	int lastPosition
	int tailPosition
	int startPosition
	int startLeft
	int repositionTreshold
	int width = 1

	@Property boolean animationFallback
	int animTargetLeft
	int animStartLeft

	boolean hasFocus

	val leftButton = getCarouselButton(true)
	val rightButton = getCarouselButton(false)

	@Property int swipeSensitivity = 20
	@Property CarouselLoadMode loadMode
	int transitionDuration = 1000
	HandlerRegistration arrowKeysHandler
	HandlerRegistration touchStartHandler
	HandlerRegistration mouseDragHandler
	HandlerRegistration moveHandler
	HandlerRegistration mouseWheelHandler

	new() {
		styleName = STYLE_NAME

		widget = new FlowPanel => [
			styleName = STYLE_CAROUSEL_PANEL
			add(new SimplePanel(childPanel) => [styleName = STYLE_CHILD_PANEL_WRAPPER])
			add(leftButton)
			add(rightButton)
		]

		addFocusHandler[hasFocus = true]
		addBlurHandler[hasFocus = false]
	}

	def private getCarouselButton(boolean left) {
		new Button => [
			styleName = STYLE_CAROUSEL_BUTTON
			addStyleName = if(left) STYLE_LEFT_BUTTON else STYLE_RIGHT_BUTTON
			addClickHandler([scroll(if(left) -1 else 1)])
		]
	}

	def setMouseDragEnabled(boolean enabled) {
		mouseDragHandler?.removeHandler
		mouseDragHandler = if (enabled)
			childPanel.addDomHandler([onDragStart(screenX)], MouseDownEvent::type)
	}

	def setTouchDragEnabled(boolean enabled) {
		touchStartHandler?.removeHandler
		touchStartHandler = if (enabled)
			childPanel.addDomHandler([onDragStart(touches.get(0).screenX)], TouchStartEvent::type)
	}

	def setButtonsVisible(boolean visible) {
		leftButton.setVisible(visible)
		rightButton.setVisible(visible)
	}

	def setMouseWheelEnabled(boolean enabled) {
		mouseWheelHandler?.removeHandler
		mouseWheelHandler = if (enabled)
			childPanel.addDomHandler(
				[
					scroll(deltaY)
					preventDefault
				], MouseWheelEvent::type)
	}

	def setArrowKeysMode(ArrowKeysMode arrowKeysMode) {
		arrowKeysHandler?.removeHandler
		arrowKeysHandler = if (arrowKeysMode != null && arrowKeysMode != ArrowKeysMode::DISABLED) {
			arrowKeysHandler = Event::addNativePreviewHandler(
				[
					if (Event::getTypeInt(nativeEvent.type) == Event::ONKEYDOWN &&
						(arrowKeysMode == ArrowKeysMode::ALWAYS || hasFocus)) {
						switch (nativeEvent.keyCode) {
							case KeyCodes::KEY_RIGHT: scroll(1)
							case KeyCodes::KEY_LEFT: scroll(-1)
						}
					}])

		}
	}

	def addListener(CarouselWidgetListener listener) {
		listeners.add(listener)
	}

	def setWidgets(List<Widget> _widgets) {
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
		]
	}

	def private getSelectedWidget() {
		getWrapper(index).widget
	}

	def private getWrapper(int index) {
		childPanel.getWidget(index) as SimplePanel
	}

	def private onDragStart(int position) {
		startLeft = childPanel.element.absoluteLeft
		startPosition = position
		runTimer.cancel
		anim.cancel
		moveHandler?.removeHandler
		moveHandler = Event::addNativePreviewHandler(
			[
				switch Event::getTypeInt(nativeEvent.type) {
					case Event::ONMOUSEMOVE:
						onDragMove(nativeEvent.screenX)
					case Event::ONTOUCHMOVE:
						onDragMove(nativeEvent.touches.get(0).screenX)
					case Event::ONMOUSEUP:
						onDragEnd()
					case Event::ONTOUCHEND:
						onDragEnd()
				}
				nativeEvent.stopPropagation
				nativeEvent.preventDefault
			])

		onDragMove(position)
		tailPosition = position
	}

	def private getCurrentMarginLeft() {
		prependedChildren * -width
	}

	def private onDragMove(int position) {
		removeStyleName(STYLE_TRANSITIONED)
		childPanel.element.style.setLeft(
			startLeft - startPosition + position - currentMarginLeft - element.offsetLeft,
			PX
		)

		lastPosition = position
		val Timer timer = [|tailPosition = position]
		timer.schedule(50)
	}

	def private onDragEnd() {
		val velocityShift = (tailPosition - lastPosition) * swipeSensitivity / width
		if (velocityShift != 0) {
			scroll(velocityShift)
		} else {
			val dragLength = (startPosition - lastPosition) / width as double
			var dragShift = if(Math::abs(dragLength) < 0.5) 0 else Math::signum(dragLength) as int

			scroll(dragShift)
		}

		moveHandler?.removeHandler
		moveHandler = null
	}

	def scroll(int change) {
		scrollToPanelIndex(index + change)
	}

	def scrollTo(int widgetIndex) {
		widgets.get(widgetIndex).scrollTo
	}

	def scrollTo(Widget widget) {
		val wrapper = widget.parent
		if (wrapper != null) {
			scrollToPanelIndex(childPanel.getWidgetIndex(wrapper))
		}
	}

	def private scrollToPanelIndex(int _index) {
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
			childPanel.insert(wrap(null), 0)
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

	def setCarouselWidth(int width) {
		this.width = Math::max(width, 1)
		removeStyleName(STYLE_TRANSITIONED)

		childPanel.element.style => [
			setFontSize(width, PX)
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
	}
}

