package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.event.dom.client.MouseDownEvent
import com.google.gwt.event.dom.client.TouchStartEvent
import com.google.gwt.event.shared.HandlerRegistration
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.Timer

import static com.google.gwt.dom.client.Style$Unit.*

abstract class DraggableCarouselWidget extends AnimatedCarouselWidget {

	int lastPosition
	int tailPosition
	int startPosition
	int startLeft

	@Property int swipeSensitivity = 20
	HandlerRegistration touchStartHandler
	HandlerRegistration mouseDragHandler
	HandlerRegistration moveHandler


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

	def private onDragStart(int position) {
		startLeft = childPanel.element.absoluteLeft
		startPosition = position
		runTimer.cancel
		anim.cancel
		moveHandler?.removeHandler
		moveHandler = Event::addNativePreviewHandler[
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
		]

		onDragMove(position)
		tailPosition = position
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

}
