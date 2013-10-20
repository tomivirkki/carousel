package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.event.dom.client.MouseDownEvent
import com.google.gwt.event.dom.client.TouchStartEvent
import com.google.gwt.event.shared.HandlerRegistration
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.Timer

abstract class DraggableCarouselWidget extends AnimatedCarouselWidget {

	int lastPosition
	int tailPosition
	int startPosition
	int panelStartPosition

	@Property int swipeSensitivity = 20
	HandlerRegistration touchStartHandler
	HandlerRegistration mouseDragHandler
	HandlerRegistration moveHandler

	def setMouseDragEnabled(boolean enabled) {
		mouseDragHandler?.removeHandler
		mouseDragHandler = if (enabled)
			childPanel.addDomHandler([onDragStart(if(horizontal) screenX else screenY)], MouseDownEvent::type)
	}

	def setTouchDragEnabled(boolean enabled) {
		touchStartHandler?.removeHandler
		touchStartHandler = if (enabled) {
			childPanel.addDomHandler(
				[
					onDragStart(
						if(horizontal) touches.get(0).screenX else touches.get(0).screenY
					)], TouchStartEvent::type)
		}
	}

	def private onDragStart(int position) {
		if (widgets.size > 1) {
			unhideAllWidgets
			panelStartPosition = childPanelCurrentPosition
			startPosition = position
			runTimer.cancel
			anim.cancel
			moveHandler?.removeHandler
			moveHandler = Event::addNativePreviewHandler [
				switch Event::getTypeInt(nativeEvent.type) {
					case Event::ONMOUSEMOVE:
						onDragMove(if(horizontal) nativeEvent.screenX else nativeEvent.screenY)
					case Event::ONTOUCHMOVE: {
						val touch = nativeEvent.touches.get(0)
						onDragMove(if(horizontal) touch.screenX else touch.screenY)
					}
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
	}

	def private onDragMove(int position) {
		removeStyleName(STYLE_TRANSITIONED)

		setChildPanelPosition(panelStartPosition - startPosition + position)

		lastPosition = position
		val Timer timer = [|tailPosition = position]
		timer.schedule(50)
	}

	def private onDragEnd() {
		val velocityShift = (tailPosition - lastPosition) * swipeSensitivity / measure
		if (velocityShift != 0) {
			scroll(velocityShift)
		} else {
			val dragPixels = startPosition - lastPosition
			if (Math::abs(dragPixels) < 5) {
				setChildPanelPosition(index * -measure - currentMargin)
				hideNonVisibleWidgets			
			} else {
				val dragLength = dragPixels / measure as double
				var dragShift = if(Math::abs(dragLength) < 0.5) 0 else Math::signum(dragLength) as int

				scroll(dragShift)
			}
		}

		moveHandler?.removeHandler
		moveHandler = null
	}

}
